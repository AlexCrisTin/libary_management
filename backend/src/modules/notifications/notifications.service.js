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
 * Lấy luồng thông báo chung của toàn bộ độc giả cho thủ thư/admin.
 */
exports.getAllNotifications = async ({ page = 1, limit = 100 }) => {
    const offset = (page - 1) * limit;
    const [countRows] = await db.query('SELECT COUNT(*) AS total FROM notifications');
    const total = countRows[0].total;
    const [rows] = await db.query(
        `SELECT
            n.notification_id,
            n.reader_id,
            n.title,
            n.content,
            n.type,
            n.reference_id,
            n.is_read,
            n.created_at,
            r.full_name AS reader_name,
            r.reader_code
         FROM notifications n
         JOIN readers r ON n.reader_id = r.reader_id
         ORDER BY n.created_at DESC
         LIMIT ? OFFSET ?`,
        [Number(limit), Number(offset)]
    );

    return {
        total,
        page: Number(page),
        limit: Number(limit),
        total_pages: Math.ceil(total / limit),
        data: rows
    };
};

/**
 * Các thông báo nghiệp vụ dành cho thủ thư/admin.
 *
 * Đây là một luồng công việc động, không dùng bảng `notifications` vì bảng đó
 * lưu thông báo đã gửi riêng cho độc giả. Khi một yêu cầu được xử lý hoặc tin
 * nhắn được đọc, mục tương ứng sẽ tự biến mất khỏi danh sách này.
 */
exports.getLibrarianNotifications = async ({ page = 1, limit = 100 }) => {
    const normalizedPage = Math.max(1, Number(page) || 1);
    const normalizedLimit = Math.min(200, Math.max(1, Number(limit) || 100));
    const offset = (normalizedPage - 1) * normalizedLimit;
    const feedSql = `
        SELECT
            CONCAT('pickup:', pr.reservation_id) AS notification_id,
            pr.reservation_id AS reference_id,
            'pickup_request' AS type,
            'Yêu cầu đặt slot mới' AS title,
            CONCAT('Độc giả ', r.full_name, ' muốn giữ sách "', br.title, '" để đến nhận.') AS content,
            pr.requested_at AS created_at,
            r.reader_id,
            r.full_name AS reader_name,
            r.reader_code
        FROM pickup_reservations pr
        JOIN readers r ON r.reader_id = pr.reader_id
        JOIN bibliographic_records br ON br.bib_id = pr.bib_id
        WHERE pr.status = 'pending'

        UNION ALL

        SELECT
            CONCAT('hold:', h.hold_id) AS notification_id,
            h.hold_id AS reference_id,
            'hold_request' AS type,
            'Đăng ký chờ sách mới' AS title,
            CONCAT('Độc giả ', r.full_name, ' đăng ký chờ sách "', br.title,
                   '" (vị trí ', COALESCE(h.queue_position, 1), ' trong hàng chờ).') AS content,
            h.requested_at AS created_at,
            r.reader_id,
            r.full_name AS reader_name,
            r.reader_code
        FROM holds h
        JOIN readers r ON r.reader_id = h.reader_id
        JOIN bibliographic_records br ON br.bib_id = h.bib_id
        WHERE h.status = 'waiting'
          AND (h.expires_at IS NULL OR h.expires_at > NOW())

        UNION ALL

        SELECT
            CONCAT('renewal:', rr.request_id) AS notification_id,
            rr.request_id AS reference_id,
            'renewal_request' AS type,
            'Yêu cầu gia hạn mới' AS title,
            CONCAT('Độc giả ', r.full_name, ' xin gia hạn sách "', br.title,
                   '" thêm ', rr.requested_days, ' ngày.') AS content,
            rr.created_at AS created_at,
            r.reader_id,
            r.full_name AS reader_name,
            r.reader_code
        FROM renewal_requests rr
        JOIN readers r ON r.reader_id = rr.reader_id
        JOIN borrow_transactions bt ON bt.tx_id = rr.tx_id
        JOIN book_copies bc ON bc.copy_id = bt.copy_id
        JOIN bibliographic_records br ON br.bib_id = bc.bib_id
        WHERE rr.status = 'pending'

        UNION ALL

        SELECT
            CONCAT('overdue:', bt.tx_id) AS notification_id,
            bt.tx_id AS reference_id,
            'overdue_loan' AS type,
            'Sách đang quá hạn' AS title,
            CONCAT('Sách "', br.title, '" của ', r.full_name, ' đã quá hạn ',
                   DATEDIFF(CURDATE(), bt.due_date), ' ngày.') AS content,
            TIMESTAMP(bt.due_date) AS created_at,
            r.reader_id,
            r.full_name AS reader_name,
            r.reader_code
        FROM borrow_transactions bt
        JOIN readers r ON r.reader_id = bt.reader_id
        JOIN book_copies bc ON bc.copy_id = bt.copy_id
        JOIN bibliographic_records br ON br.bib_id = bc.bib_id
        WHERE bt.status IN ('borrowed', 'overdue') AND bt.due_date < CURDATE()

        UNION ALL

        SELECT
            CONCAT('fine:', bt.tx_id) AS notification_id,
            bt.tx_id AS reference_id,
            'unpaid_fine' AS type,
            'Khoản phạt chưa thu' AS title,
            CONCAT('Độc giả ', r.full_name, ' còn khoản phạt ',
                   FORMAT(
                       GREATEST(
                           COALESCE(bt.fine_amount, 0),
                           CASE
                               WHEN bt.return_date IS NOT NULL AND bt.return_date > bt.due_date
                               THEN DATEDIFF(bt.return_date, bt.due_date) * 2000
                               ELSE 0
                           END
                       ),
                       0
                   ), ' VNĐ cho sách "', br.title, '".') AS content,
            COALESCE(bt.reported_at, TIMESTAMP(bt.return_date), TIMESTAMP(bt.due_date)) AS created_at,
            r.reader_id,
            r.full_name AS reader_name,
            r.reader_code
        FROM borrow_transactions bt
        JOIN readers r ON r.reader_id = bt.reader_id
        JOIN book_copies bc ON bc.copy_id = bt.copy_id
        JOIN bibliographic_records br ON br.bib_id = bc.bib_id
        WHERE bt.fine_paid = 0
          AND bt.status NOT IN ('borrowed', 'overdue')
          AND (
              bt.fine_amount > 0 OR
              (bt.return_date IS NOT NULL AND bt.return_date > bt.due_date)
          )

        UNION ALL

        SELECT
            CONCAT('message:', r.reader_id) AS notification_id,
            r.reader_id AS reference_id,
            'unread_message' AS type,
            'Tin nhắn độc giả chưa đọc' AS title,
            CONCAT(COUNT(cm.message_id), ' tin nhắn chưa đọc từ ', r.full_name, '.') AS content,
            MAX(cm.created_at) AS created_at,
            r.reader_id,
            r.full_name AS reader_name,
            r.reader_code
        FROM chat_messages cm
        JOIN readers r ON r.reader_id = cm.reader_id
        WHERE cm.sender_role = 'reader' AND cm.is_read = 0
        GROUP BY r.reader_id, r.full_name, r.reader_code
    `;

    const [countRows] = await db.query(
        `SELECT COUNT(*) AS total FROM (${feedSql}) librarian_feed`
    );
    const total = Number(countRows[0].total) || 0;
    const [rows] = await db.query(
        `SELECT * FROM (${feedSql}) librarian_feed
         ORDER BY created_at DESC, notification_id ASC
         LIMIT ? OFFSET ?`,
        [normalizedLimit, offset]
    );

    return {
        total,
        page: normalizedPage,
        limit: normalizedLimit,
        total_pages: Math.max(1, Math.ceil(total / normalizedLimit)),
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
