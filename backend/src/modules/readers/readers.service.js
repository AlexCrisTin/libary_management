const db = require('../../config/db');
const { v4: uuidv4 } = require('uuid');

const parseJSONField = (data, defaultValue = []) => {
    if (!data) return defaultValue;
    if (typeof data === 'object') return data;
    try {
        return JSON.parse(data);
    } catch {
        return defaultValue;
    }
};

/**
 * 1. Lấy danh sách toàn bộ độc giả (Thủ thư xem, hỗ trợ tìm kiếm và lọc)
 */
exports.getAllReaders = async ({ keyword = '', reader_type = '', status = '', page = 1, limit = 10 }) => {
    const offset = (page - 1) * limit;
    const params = [];
    const where = [];

    if (keyword.trim()) {
        where.push('(r.full_name LIKE ? OR r.reader_code LIKE ? OR r.phone LIKE ? OR r.email LIKE ?)');
        const kw = `%${keyword.trim()}%`;
        params.push(kw, kw, kw, kw);
    }

    if (reader_type.trim()) {
        where.push('r.reader_type = ?');
        params.push(reader_type.trim());
    }

    if (status.trim()) {
        where.push('r.status = ?');
        params.push(status.trim());
    }

    const whereClause = where.length > 0 ? `WHERE ${where.join(' AND ')}` : '';

    const countSql = `SELECT COUNT(*) AS total FROM readers r ${whereClause}`;
    const [countRows] = await db.query(countSql, params);
    const total = countRows[0].total;

    const sql = `
        SELECT 
            r.*,
            u.username,
            COUNT(CASE WHEN b.status = 'borrowed' THEN 1 END) AS currently_borrowed_count
        FROM readers r
        LEFT JOIN users u ON r.user_id = u.user_id
        LEFT JOIN borrow_transactions b ON r.reader_id = b.reader_id
        ${whereClause}
        GROUP BY r.reader_id
        ORDER BY r.created_at DESC
        LIMIT ? OFFSET ?
    `;

    const [rows] = await db.query(sql, [...params, Number(limit), Number(offset)]);

    return {
        total,
        page: Number(page),
        limit: Number(limit),
        totalPages: Math.ceil(total / limit),
        items: rows
    };
};

/**
 * 2. Lấy chi tiết một độc giả (kèm thông tin thẻ và sở thích đọc)
 */
exports.getReaderById = async (readerId) => {
    const sql = `
        SELECT 
            r.*,
            u.username,
            u.is_active AS user_active,
            p.preferred_subjects,
            p.preferred_authors,
            p.preferred_langs,
            p.reading_pace,
            COUNT(CASE WHEN b.status = 'borrowed' THEN 1 END) AS currently_borrowed_count
        FROM readers r
        LEFT JOIN users u ON r.user_id = u.user_id
        LEFT JOIN reader_preferences p ON r.reader_id = p.reader_id
        LEFT JOIN borrow_transactions b ON r.reader_id = b.reader_id
        WHERE r.reader_id = ?
        GROUP BY r.reader_id
    `;
    const [rows] = await db.query(sql, [readerId]);
    if (rows.length === 0) return null;

    const reader = rows[0];
    return {
        ...reader,
        preferred_subjects: parseJSONField(reader.preferred_subjects),
        preferred_authors: parseJSONField(reader.preferred_authors),
        preferred_langs: parseJSONField(reader.preferred_langs)
    };
};

/**
 * 3. Thêm mới độc giả tại quầy & Cấp thẻ (Thủ thư)
 */
exports.createReader = async (data) => {
    const readerId = uuidv4();
    const readerCode = data.reader_code || `LIB-${new Date().getFullYear()}-${Date.now().toString().slice(-5)}`;

    // Kiểm tra trùng mã độc giả
    const [existing] = await db.query('SELECT reader_id FROM readers WHERE reader_code = ?', [readerCode]);
    if (existing.length > 0) {
        throw new Error(`Mã độc giả (${readerCode}) đã tồn tại!`);
    }

    const {
        full_name,
        birth_date = null,
        phone = null,
        email = null,
        reader_type = 'student',
        faculty = null,
        max_books = 5,
        avatar_url = null,
        user_id = null
    } = data;

    // Ngày cấp là hôm nay, hạn thẻ mặc định 1 năm
    const cardIssued = new Date();
    const cardExpired = new Date();
    cardExpired.setFullYear(cardExpired.getFullYear() + 1);

    const sql = `
        INSERT INTO readers (
            reader_id, user_id, reader_code, full_name, birth_date, 
            phone, email, reader_type, faculty, card_issued, card_expired, 
            status, max_books, avatar_url
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', ?, ?)
    `;

    await db.query(sql, [
        readerId, user_id, readerCode, full_name, birth_date,
        phone, email, reader_type, faculty, cardIssued, cardExpired,
        Number(max_books), avatar_url
    ]);

    return {
        reader_id: readerId,
        reader_code: readerCode,
        full_name,
        reader_type,
        card_issued: cardIssued,
        card_expired: cardExpired,
        status: 'active',
        max_books: Number(max_books)
    };
};

/**
 * 4. Chỉnh sửa thông tin độc giả (Thủ thư)
 */
exports.updateReader = async (readerId, updateData) => {
    const fields = [];
    const values = [];

    const allowed = ['full_name', 'birth_date', 'phone', 'email', 'reader_type', 'faculty', 'max_books', 'avatar_url'];
    allowed.forEach((col) => {
        if (updateData[col] !== undefined) {
            fields.push(`${col} = ?`);
            values.push(updateData[col]);
        }
    });

    if (fields.length === 0) return false;

    values.push(readerId);
    const sql = `UPDATE readers SET ${fields.join(', ')} WHERE reader_id = ?`;
    const [result] = await db.query(sql, values);
    return result.affectedRows > 0;
};

/**
 * 5. Quản lý Thẻ độc giả: Gia hạn thẻ hoặc Khóa/Mở khóa thẻ (Thủ thư)
 */
exports.updateCardStatus = async (readerId, { status, card_expired }) => {
    const fields = [];
    const values = [];

    if (status) {
        if (!['active', 'suspended', 'expired'].includes(status)) {
            throw new Error('Trạng thái thẻ không hợp lệ! (Chỉ chấp nhận active, suspended, expired)');
        }
        fields.push('status = ?');
        values.push(status);
    }

    if (card_expired) {
        fields.push('card_expired = ?');
        values.push(card_expired);
    }

    if (fields.length === 0) return false;

    values.push(readerId);
    const sql = `UPDATE readers SET ${fields.join(', ')} WHERE reader_id = ?`;
    const [result] = await db.query(sql, values);
    return result.affectedRows > 0;
};

/**
 * 6. Xóa độc giả (Kiểm tra xem có sách đang mượn không)
 */
exports.deleteReader = async (readerId) => {
    // Kiểm tra xem độc giả có đang giữ sách chưa trả không
    const [borrowing] = await db.query(
        "SELECT tx_id FROM borrow_transactions WHERE reader_id = ? AND status = 'borrowed'",
        [readerId]
    );

    if (borrowing.length > 0) {
        throw new Error('Không thể xóa độc giả này vì đang có sách mượn chưa trả!');
    }

    const [result] = await db.query('DELETE FROM readers WHERE reader_id = ?', [readerId]);
    return result.affectedRows > 0;
};

/**
 * 7. Xem danh sách sách đang mượn của 1 độc giả
 */
exports.getBorrowingBooks = async (readerId) => {
    const sql = `
        SELECT 
            b.tx_id,
            b.borrow_date,
            b.due_date,
            b.renewed_count,
            DATEDIFF(CURDATE(), b.due_date) AS overdue_days,
            c.copy_id,
            c.barcode,
            c.condition,
            r.title,
            r.isbn,
            r.cover_url
        FROM borrow_transactions b
        JOIN book_copies c ON b.copy_id = c.copy_id
        JOIN bibliographic_records r ON c.bib_id = r.bib_id
        WHERE b.reader_id = ? AND b.status = 'borrowed'
        ORDER BY b.due_date ASC
    `;
    const [rows] = await db.query(sql, [readerId]);
    return rows;
};

/**
 * 8. Xem toàn bộ lịch sử mượn trả của 1 độc giả
 */
exports.getBorrowHistory = async (readerId) => {
    const sql = `
        SELECT 
            b.*,
            c.barcode,
            r.title,
            r.isbn
        FROM borrow_transactions b
        JOIN book_copies c ON b.copy_id = c.copy_id
        JOIN bibliographic_records r ON c.bib_id = r.bib_id
        WHERE b.reader_id = ?
        ORDER BY b.borrow_date DESC
    `;
    const [rows] = await db.query(sql, [readerId]);
    return rows;
};
