const db = require('../../config/db');
const { v4: uuidv4 } = require('uuid');
const { normalizePagination } = require('../../utils/pagination');

/**
 * 1. Đăng ký báo khi có sách
 * Đây chỉ là đăng ký nhận thông báo, không giữ hoặc ưu tiên bản sao.
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
            throw new Error('Thẻ thư viện của bạn đã hết hạn, không thể đăng ký báo khi có!');
        }
    }

    // 2. Kiểm tra đầu sách
    const [books] = await db.query(
        'SELECT * FROM bibliographic_records WHERE bib_id = ? AND archived_at IS NULL',
        [bib_id]
    );
    if (books.length === 0) {
        throw new Error('Không tìm thấy thông tin đầu sách này!');
    }
    const book = books[0];

    // Kiểm tra độc giả đã đăng ký báo khi có cho đầu sách này chưa.
    const [existingHolds] = await db.query(
        `SELECT hold_id, status, queue_position 
         FROM holds 
         WHERE bib_id = ? AND reader_id = ?
           AND status IN ('waiting', 'notified')
           AND (expires_at IS NULL OR expires_at > NOW())`,
        [bib_id, reader_id]
    );
    if (existingHolds.length > 0) {
        const currentHold = existingHolds[0];
        throw new Error(
            `Bạn đã đăng ký báo khi có cho đầu sách này (Trạng thái: ${currentHold.status})!`
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
        throw new Error('Bạn hiện đang mượn cuốn sách này rồi, không cần đăng ký báo khi có!');
    }

    // Chỉ cho đăng ký báo khi có khi không còn bản sao available.
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
            `Đầu sách này hiện vẫn còn ${available_copies} cuốn sẵn sàng trên kệ! Bạn có thể đặt slot hoặc đến mượn trực tiếp.`
        );
    }

    const holdId = uuidv4();

    // Tạo đăng ký nhận thông báo có hiệu lực trong 14 ngày.
    await db.query(
        `INSERT INTO holds
         (hold_id, reader_id, bib_id, status, queue_position, expires_at)
         VALUES (?, ?, ?, 'waiting', NULL, DATE_ADD(NOW(), INTERVAL 14 DAY))`,
        [holdId, reader_id, bib_id]
    );

    return {
        hold_id: holdId,
        reader_id,
        bib_id,
        book_title: book.title,
        status: 'waiting',
        valid_days: 14,
        requested_at: new Date()
    };
};

/**
 * 2. Độc giả xem danh sách đăng ký báo khi có
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
 * 3. Thủ thư xem toàn bộ danh sách báo khi có
 */
exports.getAllHolds = async ({ bib_id = '', reader_id = '', status = '', page = 1, limit = 10 }) => {
    const pagination = normalizePagination(page, limit);
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

    if (status && status !== 'all') {
        if (status === 'active') {
            where.push(`((h.status = 'waiting' AND (h.expires_at IS NULL OR h.expires_at > NOW()))
                        OR (h.status = 'notified' AND h.expires_at > NOW()))`);
        } else {
            where.push('h.status = ?');
            params.push(status);
        }
    } else if (!status) {
        // Mặc định chỉ hiển thị đăng ký đang chờ hoặc vừa được thông báo.
        where.push(`((h.status = 'waiting' AND (h.expires_at IS NULL OR h.expires_at > NOW()))
                    OR (h.status = 'notified' AND h.expires_at > NOW()))`);
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
        ORDER BY h.requested_at ASC
        LIMIT ? OFFSET ?
    `;

    const [rows] = await db.query(sql, [...params, pagination.limit, pagination.offset]);

    return {
        total,
        page: pagination.page,
        limit: pagination.limit,
        total_pages: Math.ceil(total / pagination.limit),
        data: rows
    };
};

/**
 * 4. Hủy đăng ký báo khi có
 * Độc giả tự hủy hoặc Thủ thư hủy giúp
 */
exports.cancelHold = async ({ hold_id, reader_id, user_role }) => {
    const [holds] = await db.query('SELECT * FROM holds WHERE hold_id = ?', [hold_id]);
    if (holds.length === 0) {
        throw new Error('Không tìm thấy đăng ký báo khi có này!');
    }

    const hold = holds[0];

    // Nếu người hủy là độc giả, kiểm tra quyền sở hữu
    if (user_role === 'reader' && hold.reader_id !== reader_id) {
        throw new Error('Bạn không có quyền hủy đăng ký của độc giả khác!');
    }

    // Chỉ có thể hủy các yêu cầu đang chờ (waiting) hoặc được báo nhận (notified)
    if (!['waiting', 'notified'].includes(hold.status)) {
        throw new Error(`Không thể hủy đăng ký đã ở trạng thái: ${hold.status}!`);
    }

    const conn = await db.getConnection();
    try {
        await conn.beginTransaction();

        // Cập nhật trạng thái hold thành 'cancelled'
        await conn.query(
            'UPDATE holds SET status = "cancelled" WHERE hold_id = ?',
            [hold_id]
        );

        await conn.commit();

        return {
            hold_id,
            status: 'cancelled',
            message: 'Hủy đăng ký báo khi có thành công'
        };
    } catch (error) {
        await conn.rollback();
        throw error;
    } finally {
        conn.release();
    }
};
