const db = require('../../config/db');
const { v4: uuidv4 } = require('uuid');

/**
 * 1. Cho mượn sách (Borrow Book)
 * Thủ thư thực hiện tại quầy hoặc thông qua quét mã
 */
exports.borrowBook = async ({ reader_id, reader_code, copy_id, barcode, due_days = 14, issued_by }) => {
    // 1. Kiểm tra thông tin độc giả
    let reader = null;
    if (reader_id) {
        const [rows] = await db.query('SELECT * FROM readers WHERE reader_id = ?', [reader_id]);
        reader = rows[0];
    } else if (reader_code) {
        const [rows] = await db.query('SELECT * FROM readers WHERE reader_code = ?', [reader_code]);
        reader = rows[0];
    }

    if (!reader) {
        throw new Error('Không tìm thấy hồ sơ độc giả!');
    }

    // Kiểm tra trạng thái thẻ độc giả
    if (reader.status !== 'active') {
        throw new Error(`Thẻ độc giả đang không hoạt động (Trạng thái: ${reader.status})!`);
    }

    // Kiểm tra hạn thẻ độc giả
    if (reader.card_expired) {
        const expiredDate = new Date(reader.card_expired);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        if (expiredDate < today) {
            throw new Error('Thẻ thư viện của độc giả đã hết hạn sử dụng!');
        }
    }

    // Kiểm tra số lượng sách độc giả đang mượn
    const [borrowCount] = await db.query(
        `SELECT COUNT(*) AS active_count 
         FROM borrow_transactions 
         WHERE reader_id = ? AND status IN ('borrowed', 'overdue')`,
        [reader.reader_id]
    );

    const activeCount = borrowCount[0].active_count;
    if (activeCount >= (reader.max_books || 5)) {
        throw new Error(`Độc giả đã mượn tối đa ${reader.max_books || 5} cuốn sách, không thể mượn thêm!`);
    }

    // 2. Kiểm tra bản sao sách (Book Copy)
    let copy = null;
    if (copy_id) {
        const [rows] = await db.query(
            `SELECT bc.*, br.title, br.isbn 
             FROM book_copies bc 
             JOIN bibliographic_records br ON bc.bib_id = br.bib_id 
             WHERE bc.copy_id = ?`,
            [copy_id]
        );
        copy = rows[0];
    } else if (barcode) {
        const [rows] = await db.query(
            `SELECT bc.*, br.title, br.isbn 
             FROM book_copies bc 
             JOIN bibliographic_records br ON bc.bib_id = br.bib_id 
             WHERE bc.barcode = ?`,
            [barcode]
        );
        copy = rows[0];
    }

    if (!copy) {
        throw new Error('Không tìm thấy cuốn sách vật lý tương ứng (mã vạch hoặc mã sách không đúng)!');
    }

    // Kiểm tra trạng thái bản sách
    if (copy.status === 'borrowed') {
        throw new Error('Cuốn sách này hiện đang có người khác mượn!');
    }
    if (copy.status === 'lost') {
        throw new Error('Cuốn sách này đã được báo mất, không thể cho mượn!');
    }
    if (copy.status === 'processing') {
        throw new Error('Cuốn sách này đang trong quá trình xử lý kỹ thuật!');
    }

    // Nếu sách đang ở trạng thái 'reserved' (giữ trước) -> Phải đúng độc giả này đặt
    if (copy.status === 'reserved') {
        const [holds] = await db.query(
            `SELECT * FROM holds 
             WHERE bib_id = ? AND reader_id = ? AND status IN ('waiting', 'notified') 
             LIMIT 1`,
            [copy.bib_id, reader.reader_id]
        );
        if (holds.length === 0) {
            throw new Error('Cuốn sách này đang được giữ ưu tiên cho độc giả khác đặt trước!');
        }
    }

    // 3. Thực thi MySQL Transaction để đảm bảo tính toàn vẹn dữ liệu
    const conn = await db.getConnection();
    try {
        await conn.beginTransaction();

        const txId = uuidv4();
        const borrowDate = new Date().toISOString().split('T')[0];
        const dueDateObj = new Date();
        dueDateObj.setDate(dueDateObj.getDate() + Number(due_days));
        const dueDate = dueDateObj.toISOString().split('T')[0];

        // Ghi nhận lượt mượn vào bảng borrow_transactions
        await conn.query(
            `INSERT INTO borrow_transactions (
                tx_id, reader_id, copy_id, borrow_date, due_date, 
                status, issued_by
            ) VALUES (?, ?, ?, ?, ?, 'borrowed', ?)`,
            [txId, reader.reader_id, copy.copy_id, borrowDate, dueDate, issued_by || null]
        );

        // Cập nhật trạng thái bản sách thành 'borrowed'
        await conn.query(
            'UPDATE book_copies SET status = "borrowed" WHERE copy_id = ?',
            [copy.copy_id]
        );

        // Nếu độc giả từng đặt trước đầu sách này -> Chuyển hold thành 'fulfilled'
        await conn.query(
            `UPDATE holds 
             SET status = 'fulfilled' 
             WHERE bib_id = ? AND reader_id = ? AND status IN ('waiting', 'notified')`,
            [copy.bib_id, reader.reader_id]
        );

        await conn.commit();

        return {
            tx_id: txId,
            reader: {
                reader_id: reader.reader_id,
                reader_code: reader.reader_code,
                full_name: reader.full_name,
                currently_borrowed: activeCount + 1,
                max_books: reader.max_books
            },
            book: {
                copy_id: copy.copy_id,
                barcode: copy.barcode,
                title: copy.title,
                condition: copy.condition
            },
            borrow_date: borrowDate,
            due_date: dueDate,
            status: 'borrowed'
        };
    } catch (error) {
        await conn.rollback();
        throw error;
    } finally {
        conn.release();
    }
};

/**
 * 2. Nhận trả sách (Return Book)
 * Thủ thư quét mã vạch hoặc nhập mã giao dịch
 */
exports.returnBook = async ({ barcode, copy_id, tx_id, returned_to, condition, fine_rate_per_day = 2000 }) => {
    // 1. Tìm giao dịch mượn đang diễn ra
    let query = `
        SELECT 
            bt.*,
            bc.barcode,
            bc.copy_id,
            bc.bib_id,
            bc.condition AS current_condition,
            br.title AS book_title,
            r.full_name AS reader_name,
            r.reader_code
        FROM borrow_transactions bt
        JOIN book_copies bc ON bt.copy_id = bc.copy_id
        JOIN bibliographic_records br ON bc.bib_id = br.bib_id
        JOIN readers r ON bt.reader_id = r.reader_id
        WHERE bt.status IN ('borrowed', 'overdue')
    `;
    const params = [];

    if (tx_id) {
        query += ' AND bt.tx_id = ?';
        params.push(tx_id);
    } else if (barcode) {
        query += ' AND bc.barcode = ?';
        params.push(barcode);
    } else if (copy_id) {
        query += ' AND bc.copy_id = ?';
        params.push(copy_id);
    } else {
        throw new Error('Vui lòng cung cấp mã vạch sách (barcode) hoặc mã giao dịch (tx_id)!');
    }

    query += ' ORDER BY bt.created_at DESC LIMIT 1';

    const [transactions] = await db.query(query, params);
    if (transactions.length === 0) {
        throw new Error('Không tìm thấy giao dịch mượn đang diễn ra cho cuốn sách này!');
    }

    const tx = transactions[0];

    // 2. Tính toán ngày quá hạn và tiền phạt (nếu có)
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const dueDate = new Date(tx.due_date);
    dueDate.setHours(0, 0, 0, 0);

    const diffMs = today.getTime() - dueDate.getTime();
    const overdueDays = diffMs > 0 ? Math.ceil(diffMs / (1000 * 60 * 60 * 24)) : 0;
    const fineAmount = overdueDays * Number(fine_rate_per_day);

    // 3. Thực thi Transaction trả sách
    const conn = await db.getConnection();
    try {
        await conn.beginTransaction();

        const returnDate = new Date().toISOString().split('T')[0];

        // Cập nhật giao dịch mượn
        await conn.query(
            `UPDATE borrow_transactions 
             SET return_date = ?, status = 'returned', returned_to = ?, fine_amount = ? 
             WHERE tx_id = ?`,
            [returnDate, returned_to || null, fineAmount, tx.tx_id]
        );

        // Kiểm tra xem đầu sách này có ai đang đặt trước trong hàng đợi (holds) không
        const [waitingHolds] = await conn.query(
            `SELECT * FROM holds 
             WHERE bib_id = ? AND status = 'waiting' 
             ORDER BY queue_position ASC, requested_at ASC 
             LIMIT 1`,
            [tx.bib_id]
        );

        let nextCopyStatus = 'available';
        let holdNotified = null;

        if (waitingHolds.length > 0) {
            // Có người đặt trước -> Giữ sách cho người tiếp theo (status: 'reserved')
            nextCopyStatus = 'reserved';
            const nextHold = waitingHolds[0];

            await conn.query(
                `UPDATE holds 
                 SET status = 'notified', notified_at = NOW(), expires_at = DATE_ADD(NOW(), INTERVAL 3 DAY) 
                 WHERE hold_id = ?`,
                [nextHold.hold_id]
            );

            holdNotified = {
                hold_id: nextHold.hold_id,
                reader_id: nextHold.reader_id,
                message: 'Cuốn sách được chuyển sang trạng thái giữ chỗ cho độc giả đặt trước.'
            };
        }

        // Cập nhật lại bản sao sách
        const newCondition = condition || tx.current_condition || 'good';
        await conn.query(
            'UPDATE book_copies SET status = ?, `condition` = ? WHERE copy_id = ?',
            [nextCopyStatus, newCondition, tx.copy_id]
        );

        await conn.commit();

        return {
            tx_id: tx.tx_id,
            reader: {
                reader_name: tx.reader_name,
                reader_code: tx.reader_code
            },
            book: {
                copy_id: tx.copy_id,
                barcode: tx.barcode,
                title: tx.book_title,
                condition: newCondition,
                next_status: nextCopyStatus
            },
            borrow_date: tx.borrow_date,
            due_date: tx.due_date,
            return_date: returnDate,
            overdue_days: overdueDays,
            fine_amount: fineAmount,
            fine_paid: fineAmount === 0,
            hold_notification: holdNotified
        };
    } catch (error) {
        await conn.rollback();
        throw error;
    } finally {
        conn.release();
    }
};

/**
 * 3. Gia hạn thời gian mượn (Renew Book)
 * Độc giả tự gia hạn hoặc Thủ thư hỗ trợ gia hạn
 */
exports.renewBook = async ({ tx_id, reader_id, user_role, extend_days = 7 }) => {
    // 1. Tìm giao dịch mượn
    const [transactions] = await db.query(
        `SELECT 
            bt.*, 
            bc.bib_id, 
            br.title AS book_title 
         FROM borrow_transactions bt 
         JOIN book_copies bc ON bt.copy_id = bc.copy_id 
         JOIN bibliographic_records br ON bc.bib_id = br.bib_id 
         WHERE bt.tx_id = ? AND bt.status IN ('borrowed', 'overdue')`,
        [tx_id]
    );

    if (transactions.length === 0) {
        throw new Error('Không tìm thấy giao dịch mượn đang diễn ra!');
    }

    const tx = transactions[0];

    // Nếu người gia hạn là độc giả, kiểm tra có đúng giao dịch của họ không
    if (user_role === 'reader' && tx.reader_id !== reader_id) {
        throw new Error('Bạn không có quyền gia hạn sách của độc giả khác!');
    }

    // Kiểm tra sách đã quá hạn chưa
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const dueDate = new Date(tx.due_date);
    dueDate.setHours(0, 0, 0, 0);

    if (today > dueDate) {
        throw new Error('Sách đã quá hạn trả! Không thể gia hạn trực tuyến, vui lòng đến thư viện.');
    }

    // Kiểm tra giới hạn số lần gia hạn (tối đa 2 lần)
    if (tx.renewed_count >= 2) {
        throw new Error('Cuốn sách này đã đạt giới hạn gia hạn tối đa (2 lần)!');
    }

    // Kiểm tra xem đầu sách có người khác đang chờ đặt trước (holds) không
    const [holds] = await db.query(
        'SELECT hold_id FROM holds WHERE bib_id = ? AND status = "waiting" LIMIT 1',
        [tx.bib_id]
    );
    if (holds.length > 0) {
        throw new Error('Đầu sách này đang có độc giả khác đặt trước nên không thể gia hạn!');
    }

    // Tính ngày trả mới
    const newDueDateObj = new Date(dueDate);
    newDueDateObj.setDate(newDueDateObj.getDate() + Number(extend_days));
    const newDueDate = newDueDateObj.toISOString().split('T')[0];

    // Cập nhật giao dịch
    await db.query(
        `UPDATE borrow_transactions 
         SET due_date = ?, renewed_count = renewed_count + 1 
         WHERE tx_id = ?`,
        [newDueDate, tx_id]
    );

    return {
        tx_id: tx.tx_id,
        book_title: tx.book_title,
        old_due_date: tx.due_date,
        new_due_date: newDueDate,
        renewed_count: tx.renewed_count + 1,
        max_renewals: 2
    };
};

/**
 * 4. Lấy danh sách các lượt mượn đang diễn ra (Active Loans)
 * Dùng cho Thủ thư quản lý hoặc Độc giả xem sách mình đang mượn
 */
exports.getActiveLoans = async ({ reader_id = '', keyword = '', status = '', page = 1, limit = 10 }) => {
    const offset = (page - 1) * limit;
    const params = [];
    const where = ["bt.status IN ('borrowed', 'overdue')"];

    if (reader_id) {
        where.push('bt.reader_id = ?');
        params.push(reader_id);
    }

    if (status) {
        where.push('bt.status = ?');
        params.push(status);
    }

    if (keyword.trim()) {
        where.push('(r.full_name LIKE ? OR r.reader_code LIKE ? OR bc.barcode LIKE ? OR br.title LIKE ?)');
        const kw = `%${keyword.trim()}%`;
        params.push(kw, kw, kw, kw);
    }

    const whereClause = `WHERE ${where.join(' AND ')}`;

    // Đếm tổng số
    const countSql = `
        SELECT COUNT(*) AS total 
        FROM borrow_transactions bt
        JOIN readers r ON bt.reader_id = r.reader_id
        JOIN book_copies bc ON bt.copy_id = bc.copy_id
        JOIN bibliographic_records br ON bc.bib_id = br.bib_id
        ${whereClause}
    `;
    const [countRows] = await db.query(countSql, params);
    const total = countRows[0].total;

    // Lấy dữ liệu chi tiết
    const sql = `
        SELECT 
            bt.tx_id,
            bt.reader_id,
            bt.copy_id,
            bt.borrow_date,
            bt.due_date,
            bt.renewed_count,
            bt.status,
            bt.fine_amount,
            bt.fine_paid,
            r.full_name AS reader_name,
            r.reader_code,
            r.phone AS reader_phone,
            bc.barcode,
            bc.condition AS copy_condition,
            br.bib_id,
            br.title AS book_title,
            br.cover_url,
            DATEDIFF(CURDATE(), bt.due_date) AS days_difference
        FROM borrow_transactions bt
        JOIN readers r ON bt.reader_id = r.reader_id
        JOIN book_copies bc ON bt.copy_id = bc.copy_id
        JOIN bibliographic_records br ON bc.bib_id = br.bib_id
        ${whereClause}
        ORDER BY bt.due_date ASC
        LIMIT ? OFFSET ?
    `;

    const [rows] = await db.query(sql, [...params, Number(limit), Number(offset)]);

    const items = rows.map(item => {
        const isOverdue = item.days_difference > 0;
        return {
            ...item,
            is_overdue: isOverdue,
            overdue_days: isOverdue ? item.days_difference : 0,
            days_left: !isOverdue ? Math.abs(item.days_difference) : 0
        };
    });

    return {
        total,
        page,
        limit,
        total_pages: Math.ceil(total / limit),
        data: items
    };
};

/**
 * 5. Lấy lịch sử mượn trả (Loan History)
 */
exports.getLoanHistory = async ({ reader_id = '', copy_id = '', status = '', from_date = '', to_date = '', page = 1, limit = 10 }) => {
    const offset = (page - 1) * limit;
    const params = [];
    const where = [];

    if (reader_id) {
        where.push('bt.reader_id = ?');
        params.push(reader_id);
    }

    if (copy_id) {
        where.push('bt.copy_id = ?');
        params.push(copy_id);
    }

    if (status) {
        where.push('bt.status = ?');
        params.push(status);
    }

    if (from_date) {
        where.push('bt.borrow_date >= ?');
        params.push(from_date);
    }

    if (to_date) {
        where.push('bt.borrow_date <= ?');
        params.push(to_date);
    }

    const whereClause = where.length > 0 ? `WHERE ${where.join(' AND ')}` : '';

    const countSql = `SELECT COUNT(*) AS total FROM borrow_transactions bt ${whereClause}`;
    const [countRows] = await db.query(countSql, params);
    const total = countRows[0].total;

    const sql = `
        SELECT 
            bt.*,
            r.full_name AS reader_name,
            r.reader_code,
            bc.barcode,
            br.title AS book_title,
            u1.username AS issued_by_user,
            u2.username AS returned_to_user
        FROM borrow_transactions bt
        JOIN readers r ON bt.reader_id = r.reader_id
        JOIN book_copies bc ON bt.copy_id = bc.copy_id
        JOIN bibliographic_records br ON bc.bib_id = br.bib_id
        LEFT JOIN users u1 ON bt.issued_by = u1.user_id
        LEFT JOIN users u2 ON bt.returned_to = u2.user_id
        ${whereClause}
        ORDER BY bt.created_at DESC
        LIMIT ? OFFSET ?
    `;

    const [rows] = await db.query(sql, [...params, Number(limit), Number(offset)]);

    return {
        total,
        page,
        limit,
        total_pages: Math.ceil(total / limit),
        data: rows
    };
};

/**
 * 6. Thu tiền phạt quá hạn (Pay Fine)
 */
exports.payFine = async ({ tx_id }) => {
    const [rows] = await db.query('SELECT * FROM borrow_transactions WHERE tx_id = ?', [tx_id]);
    if (rows.length === 0) {
        throw new Error('Không tìm thấy giao dịch này!');
    }

    const tx = rows[0];
    if (Number(tx.fine_amount) <= 0) {
        throw new Error('Giao dịch này không có tiền phạt cần thanh toán!');
    }
    if (tx.fine_paid === 1) {
        throw new Error('Tiền phạt của giao dịch này đã được thanh toán trước đó!');
    }

    await db.query('UPDATE borrow_transactions SET fine_paid = 1 WHERE tx_id = ?', [tx_id]);

    return {
        tx_id,
        fine_amount: tx.fine_amount,
        fine_paid: true,
        message: 'Đã thanh toán tiền phạt thành công'
    };
};

/**
 * 7. Báo mất sách (Report Lost Book)
 */
exports.reportLostBook = async ({ tx_id }) => {
    const [rows] = await db.query(
        `SELECT bt.*, bc.copy_id 
         FROM borrow_transactions bt 
         JOIN book_copies bc ON bt.copy_id = bc.copy_id 
         WHERE bt.tx_id = ? AND bt.status IN ('borrowed', 'overdue')`,
        [tx_id]
    );

    if (rows.length === 0) {
        throw new Error('Không tìm thấy giao dịch mượn đang hoạt động!');
    }

    const tx = rows[0];

    const conn = await db.getConnection();
    try {
        await conn.beginTransaction();

        await conn.query('UPDATE borrow_transactions SET status = "lost" WHERE tx_id = ?', [tx_id]);
        await conn.query('UPDATE book_copies SET status = "lost" WHERE copy_id = ?', [tx.copy_id]);

        await conn.commit();

        return {
            tx_id,
            copy_id: tx.copy_id,
            status: 'lost',
            message: 'Đã ghi nhận sách bị mất'
        };
    } catch (error) {
        await conn.rollback();
        throw error;
    } finally {
        conn.release();
    }
};
