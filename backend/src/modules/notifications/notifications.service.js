const db = require('../../config/db');
const { v4: uuidv4 } = require('uuid');

/**
 * 1. Tạo thông báo mới (Hệ thống hoặc các module khác gọi tự động)
 */
exports.createNotification = async ({ reader_id, title, content, type = 'system', reference_id = null }) => {
    const notificationId = uuidv4();
    const sql = `
        INSERT INTO notifications (
            notification_id, reader_id, title, content, type, reference_id, is_read, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, 0, NOW())
    `;

    await db.query(sql, [notificationId, reader_id, title, content, type, reference_id]);

    return {
        notification_id: notificationId,
        reader_id,
        title,
        content,
        type,
        reference_id,
        is_read: false,
        created_at: new Date()
    };
};

/**
 * 2. Lấy danh sách thông báo của độc giả (hỗ trợ phân trang và lọc đã đọc/chưa đọc)
 */
exports.getMyNotifications = async ({ reader_id, is_read = null, page = 1, limit = 20 }) => {
    const offset = (page - 1) * limit;
    const params = [reader_id];
    let whereClause = 'WHERE reader_id = ?';

    if (is_read !== null && is_read !== undefined && is_read !== '') {
        whereClause += ' AND is_read = ?';
        params.push(is_read === 'true' || is_read === '1' || is_read === 1 ? 1 : 0);
    }

    // Đếm tổng số thông báo
    const countSql = `SELECT COUNT(*) AS total FROM notifications ${whereClause}`;
    const [countRows] = await db.query(countSql, params);
    const total = countRows[0].total;

    // Lấy danh sách
    const sql = `
        SELECT 
            notification_id,
            reader_id,
            title,
            content,
            type,
            reference_id,
            is_read,
            created_at
        FROM notifications
        ${whereClause}
        ORDER BY created_at DESC
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
 * 3. Đếm số lượng thông báo chưa đọc (để hiển thị badge chấm đỏ trên app)
 */
exports.getUnreadCount = async ({ reader_id }) => {
    const sql = 'SELECT COUNT(*) AS unread_count FROM notifications WHERE reader_id = ? AND is_read = 0';
    const [rows] = await db.query(sql, [reader_id]);
    return {
        unread_count: rows[0].unread_count
    };
};

/**
 * 4. Đánh dấu một thông báo là đã đọc
 */
exports.markAsRead = async ({ notification_id, reader_id }) => {
    const sql = 'UPDATE notifications SET is_read = 1 WHERE notification_id = ? AND reader_id = ?';
    const [result] = await db.query(sql, [notification_id, reader_id]);

    if (result.affectedRows === 0) {
        throw new Error('Không tìm thấy thông báo hoặc bạn không có quyền cập nhật thông báo này!');
    }

    return {
        notification_id,
        is_read: true,
        message: 'Đã đánh dấu thông báo là đã đọc'
    };
};

/**
 * 5. Đánh dấu tất cả thông báo của độc giả là đã đọc
 */
exports.markAllAsRead = async ({ reader_id }) => {
    const sql = 'UPDATE notifications SET is_read = 1 WHERE reader_id = ? AND is_read = 0';
    const [result] = await db.query(sql, [reader_id]);

    return {
        updated_count: result.affectedRows,
        message: 'Đã đánh dấu tất cả thông báo là đã đọc'
    };
};

/**
 * 6. Xóa một thông báo
 */
exports.deleteNotification = async ({ notification_id, reader_id }) => {
    const sql = 'DELETE FROM notifications WHERE notification_id = ? AND reader_id = ?';
    const [result] = await db.query(sql, [notification_id, reader_id]);

    if (result.affectedRows === 0) {
        throw new Error('Không tìm thấy thông báo hoặc bạn không có quyền xóa!');
    }

    return {
        notification_id,
        message: 'Đã xóa thông báo thành công'
    };
};
