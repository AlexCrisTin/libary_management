const db = require('../../config/db');
const { v4: uuidv4 } = require('uuid');

/**
 * 1. Gửi tin nhắn mới (Độc giả hoặc Thủ thư gửi)
 */
exports.sendMessage = async ({ reader_id, sender_id, sender_role, message_text }) => {
    if (!message_text || !message_text.trim()) {
        throw new Error('Nội dung tin nhắn không được để trống!');
    }

    // Kiểm tra độc giả có tồn tại không
    const [readers] = await db.query('SELECT reader_id FROM readers WHERE reader_id = ?', [reader_id]);
    if (readers.length === 0) {
        throw new Error('Không tìm thấy cuộc trò chuyện của độc giả này!');
    }

    const messageId = uuidv4();
    const sql = `
        INSERT INTO chat_messages (
            message_id, reader_id, sender_id, sender_role, message_text, is_read, created_at
        ) VALUES (?, ?, ?, ?, ?, 0, NOW())
    `;

    await db.query(sql, [messageId, reader_id, sender_id, sender_role, message_text.trim()]);

    return {
        message_id: messageId,
        reader_id,
        sender_id,
        sender_role,
        message_text: message_text.trim(),
        is_read: false,
        created_at: new Date()
    };
};

/**
 * 2. Tải lịch sử tin nhắn trong cuộc trò chuyện của 1 độc giả
 * Đồng thời tự động đánh dấu các tin nhắn gửi đến là đã đọc
 */
exports.getMessages = async ({ reader_id, viewer_role, page = 1, limit = 50 }) => {
    const offset = (page - 1) * limit;

    // Đếm tổng số tin nhắn
    const countSql = 'SELECT COUNT(*) AS total FROM chat_messages WHERE reader_id = ?';
    const [countRows] = await db.query(countSql, [reader_id]);
    const total = countRows[0].total;

    // Lấy tin nhắn
    const sql = `
        SELECT 
            m.message_id,
            m.reader_id,
            m.sender_id,
            m.sender_role,
            m.message_text,
            m.is_read,
            m.created_at,
            u.username AS sender_username
        FROM chat_messages m
        JOIN users u ON m.sender_id = u.user_id
        WHERE m.reader_id = ?
        ORDER BY m.created_at ASC
        LIMIT ? OFFSET ?
    `;

    const [rows] = await db.query(sql, [reader_id, Number(limit), Number(offset)]);

    // Đánh dấu các tin nhắn của phía bên kia là đã đọc
    if (viewer_role === 'reader') {
        await db.query(
            'UPDATE chat_messages SET is_read = 1 WHERE reader_id = ? AND sender_role = "librarian" AND is_read = 0',
            [reader_id]
        );
    } else if (viewer_role === 'librarian' || viewer_role === 'admin') {
        await db.query(
            'UPDATE chat_messages SET is_read = 1 WHERE reader_id = ? AND sender_role = "reader" AND is_read = 0',
            [reader_id]
        );
    }

    return {
        total,
        page,
        limit,
        total_pages: Math.ceil(total / limit),
        data: rows
    };
};

/**
 * 3. Dành cho Thủ thư: Lấy danh sách tất cả các cuộc hội thoại
 * Kèm tin nhắn mới nhất và số tin chưa đọc từ phía độc giả
 */
exports.getConversations = async ({ page = 1, limit = 20 }) => {
    const offset = (page - 1) * limit;

    const countSql = 'SELECT COUNT(DISTINCT reader_id) AS total FROM chat_messages';
    const [countRows] = await db.query(countSql);
    const total = countRows[0].total;

    const sql = `
        SELECT 
            r.reader_id,
            r.full_name AS reader_name,
            r.reader_code,
            r.avatar_url,
            latest.message_text AS last_message,
            latest.created_at AS last_message_time,
            latest.sender_role AS last_sender_role,
            (
                SELECT COUNT(*) 
                FROM chat_messages 
                WHERE reader_id = r.reader_id AND is_read = 0 AND sender_role = 'reader'
            ) AS unread_count
        FROM readers r
        JOIN (
            SELECT cm.*
            FROM chat_messages cm
            INNER JOIN (
                SELECT reader_id, MAX(created_at) AS max_time
                FROM chat_messages
                GROUP BY reader_id
            ) m ON cm.reader_id = m.reader_id AND cm.created_at = m.max_time
        ) latest ON r.reader_id = latest.reader_id
        ORDER BY latest.created_at DESC
        LIMIT ? OFFSET ?
    `;

    const [rows] = await db.query(sql, [Number(limit), Number(offset)]);

    return {
        total,
        page,
        limit,
        total_pages: Math.ceil(total / limit),
        data: rows
    };
};
