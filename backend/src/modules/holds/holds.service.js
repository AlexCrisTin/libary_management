const db = require('../../config/db');
const { v4: uuidv4 } = require('uuid');

/**
 * 1. Đặt trước đầu sách (Create Hold)
 * Độc giả gửi yêu cầu khi đầu sách không còn cuốn nào sẵn có (available)
 */
exports.createHold = async ({ reader_id, bib_id }) => {
    // 1. Kiểm tra độc giả
    const [readers] = await db.query('SELECT * FROM readers WHERE reader_id = ?', [reader_id]);
    if (readers.length === 0) {
        throw new Error('Không tìm thấy hồ sơ độc giả!');
    }
    const reader = readers[0];

    if (reader.status !== 'active') {
        throw new Error(`Thẻ độc giả đang không hoạt động (Trạng thái: ${reader.status})!`);
    }

    if (reader.card_expired) {
        const expiredDate = new Date(reader.card_expired);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        if (expiredDate < today) {
            throw new Error('Thẻ thư viện của bạn đã hết hạn, không thể đặt trước sách!');
        }
    }

    // 2. Kiểm tra đầu sách
    const [books] = await db.query('SELECT * FROM bibliographic_records WHERE bib_id = ?', [bib_id]);
    if (books.length === 0) {
        throw new Error('Không tìm thấy thông tin đầu sách này!');
    }
    const book = books[0];

    // 3. Kiểm tra độc giả đã có yêu cầu đặt trước đầu sách này chưa
    const [existingHolds] = await db.query(
        `SELECT hold_id, status, queue_position 
         FROM holds 
         WHERE bib_id = ? AND reader_id = ? AND status IN ('waiting', 'notified')`,
        [bib_id, reader_id]
    );
    if (existingHolds.length > 0) {
        const currentHold = existingHolds[0];
        throw new Error(
            `Bạn đã có yêu cầu đặt trước đầu sách này (Trạng thái: ${currentHold.status}, vị trí hàng chờ: ${currentHold.queue_position})!`
        );
    }

    // 4. Kiểm tra độc giả hiện có đang giữ cuốn sách nào của đầu sách này không
    const [currentBorrows] = await db.query(
        `SELECT bt.tx_id 
         FROM borrow_transactions bt
         JOIN book_copies bc ON bt.copy_id = bc.copy_id
         WHERE bt.reader_id = ? AND bc.bib_id = ? AND bt.status IN ('borrowed', 'overdue')`,
        [reader_id, bib_id]
    );
    if (currentBorrows.length > 0) {
        throw new Error('Bạn hiện đang mượn cuốn sách này rồi, không thể đặt trước thêm!');
    }

    // 5. Kiểm tra sách rảnh trên kệ: nếu vẫn còn sách available thì không cho đặt trước
    const [copies] = await db.query(
        `SELECT COUNT(*) AS total_copies,
                COUNT(CASE WHEN status = 'available' THEN 1 END) AS available_copies
         FROM book_copies 
         WHERE bib_id = ?`,
        [bib_id]
    );
    const { total_copies, available_copies } = copies[0];

    if (total_copies === 0) {
        throw new Error('Đầu sách này hiện chưa có bản sao vật lý nào trong thư viện!');
    }

    if (available_copies > 0) {
        throw new Error(
            `Đầu sách này hiện vẫn còn ${available_copies} cuốn sẵn sàng trên kệ! Bạn có thể đến mượn trực tiếp mà không cần đặt trước.`
        );
    }

    // 6. Tính toán vị trí trong hàng đợi (queue_position)
    const [queueRow] = await db.query(
        `SELECT COALESCE(MAX(queue_position), 0) + 1 AS next_position 
         FROM holds 
         WHERE bib_id = ? AND status = 'waiting'`,
        [bib_id]
    );
    const nextPosition = queueRow[0].next_position;

    const holdId = uuidv4();

    // 7. Tạo bản ghi đặt trước
    await db.query(
        `INSERT INTO holds (hold_id, reader_id, bib_id, status, queue_position)
         VALUES (?, ?, ?, 'waiting', ?)`,
        [holdId, reader_id, bib_id, nextPosition]
    );

    return {
        hold_id: holdId,
        reader_id,
        bib_id,
        book_title: book.title,
        queue_position: nextPosition,
        status: 'waiting',
        requested_at: new Date()
    };
};

/**
 * 2. Độc giả xem danh sách sách mình đang đặt trước
 */
exports.getMyHolds = async ({ reader_id, status = '' }) => {
    const params = [reader_id];
    let whereClause = 'WHERE h.reader_id = ?';

    if (status) {
        whereClause += ' AND h.status = ?';
        params.push(status);
    }

    const sql = `
        SELECT 
            h.hold_id,
            h.reader_id,
            h.bib_id,
            h.requested_at,
            h.notified_at,
            h.expires_at,
            h.status,
            h.queue_position,
            br.title AS book_title,
            br.isbn,
            br.cover_url
        FROM holds h
        JOIN bibliographic_records br ON h.bib_id = br.bib_id
        ${whereClause}
        ORDER BY h.requested_at DESC
    `;

    const [rows] = await db.query(sql, params);
    return rows;
};

/**
 * 3. Thủ thư xem toàn bộ danh sách đặt trước (hỗ trợ lọc theo sách, độc giả, trạng thái)
 */
exports.getAllHolds = async ({ bib_id = '', reader_id = '', status = '', page = 1, limit = 10 }) => {
    const offset = (page - 1) * limit;
    const params = [];
    const where = [];

    if (bib_id) {
        where.push('h.bib_id = ?');
        params.push(bib_id);
    }

    if (reader_id) {
        where.push('h.reader_id = ?');
        params.push(reader_id);
    }

    if (status) {
        where.push('h.status = ?');
        params.push(status);
    }

    const whereClause = where.length > 0 ? `WHERE ${where.join(' AND ')}` : '';

    const countSql = `SELECT COUNT(*) AS total FROM holds h ${whereClause}`;
    const [countRows] = await db.query(countSql, params);
    const total = countRows[0].total;

    const sql = `
        SELECT 
            h.hold_id,
            h.reader_id,
            h.bib_id,
            h.requested_at,
            h.notified_at,
            h.expires_at,
            h.status,
            h.queue_position,
            r.full_name AS reader_name,
            r.reader_code,
            r.phone AS reader_phone,
            br.title AS book_title,
            br.isbn
        FROM holds h
        JOIN readers r ON h.reader_id = r.reader_id
        JOIN bibliographic_records br ON h.bib_id = br.bib_id
        ${whereClause}
        ORDER BY h.bib_id, h.queue_position ASC, h.requested_at ASC
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
 * 4. Hủy yêu cầu đặt trước (Cancel Hold)
 * Độc giả tự hủy hoặc Thủ thư hủy giúp
 */
exports.cancelHold = async ({ hold_id, reader_id, user_role }) => {
    const [holds] = await db.query('SELECT * FROM holds WHERE hold_id = ?', [hold_id]);
    if (holds.length === 0) {
        throw new Error('Không tìm thấy yêu cầu đặt trước này!');
    }

    const hold = holds[0];

    // Nếu người hủy là độc giả, kiểm tra quyền sở hữu
    if (user_role === 'reader' && hold.reader_id !== reader_id) {
        throw new Error('Bạn không có quyền hủy yêu cầu đặt trước của độc giả khác!');
    }

    // Chỉ có thể hủy các yêu cầu đang chờ (waiting) hoặc được báo nhận (notified)
    if (!['waiting', 'notified'].includes(hold.status)) {
        throw new Error(`Không thể hủy yêu cầu đặt trước đã ở trạng thái: ${hold.status}!`);
    }

    const conn = await db.getConnection();
    try {
        await conn.beginTransaction();

        // Cập nhật trạng thái hold thành 'cancelled'
        await conn.query(
            'UPDATE holds SET status = "cancelled" WHERE hold_id = ?',
            [hold_id]
        );

        // Trường hợp 1: Người hủy đang ở hàng chờ (waiting) -> Đôn các người đứng sau lên 1 bậc
        if (hold.status === 'waiting') {
            await conn.query(
                `UPDATE holds 
                 SET queue_position = queue_position - 1 
                 WHERE bib_id = ? AND status = 'waiting' AND queue_position > ?`,
                [hold.bib_id, hold.queue_position]
            );
        }

        // Trường hợp 2: Người hủy đã được báo sách về (notified - sách đang reserved riêng)
        if (hold.status === 'notified') {
            // Kiểm tra xem có người tiếp theo trong hàng chờ (waiting) không
            const [nextWaiting] = await conn.query(
                `SELECT * FROM holds 
                 WHERE bib_id = ? AND status = 'waiting' 
                 ORDER BY queue_position ASC, requested_at ASC 
                 LIMIT 1`,
                [hold.bib_id]
            );

            if (nextWaiting.length > 0) {
                // Chuyển người kế tiếp thành 'notified'
                const nextHold = nextWaiting[0];
                await conn.query(
                    `UPDATE holds 
                     SET status = 'notified', notified_at = NOW(), expires_at = DATE_ADD(NOW(), INTERVAL 3 DAY), queue_position = 0 
                     WHERE hold_id = ?`,
                    [nextHold.hold_id]
                );

                // Đôn các người xếp sau tiếp tục lên 1 bậc
                await conn.query(
                    `UPDATE holds 
                     SET queue_position = queue_position - 1 
                     WHERE bib_id = ? AND status = 'waiting' AND queue_position > ?`,
                    [hold.bib_id, nextHold.queue_position]
                );
            } else {
                // Không còn ai chờ -> Chuyển bản sách reserved trở lại available
                await conn.query(
                    `UPDATE book_copies 
                     SET status = 'available' 
                     WHERE bib_id = ? AND status = 'reserved' 
                     LIMIT 1`,
                    [hold.bib_id]
                );
            }
        }

        await conn.commit();

        return {
            hold_id,
            status: 'cancelled',
            message: 'Hủy yêu cầu đặt trước thành công'
        };
    } catch (error) {
        await conn.rollback();
        throw error;
    } finally {
        conn.release();
    }
};
