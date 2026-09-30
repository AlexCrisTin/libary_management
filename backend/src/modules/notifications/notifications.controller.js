const notificationsService = require('./notifications.service');
const { scanAndNotifyOverdue } = require('../../jobs/overdueNotification.job');
const { scanAndNotifyCardExpiration } = require('../../jobs/cardExpirationNotification.job');
const { sendSuccess, sendError } = require('../../utils/response');

/**
 * 1. GET /api/notifications - Lấy danh sách thông báo của độc giả
 */
exports.getMyNotifications = async (req, res, next) => {
    try {
        const reader_id = req.user.readerId || req.query.reader_id;
        if (!reader_id) {
            return sendError(res, 'Chức năng này chỉ dành cho độc giả hoặc tài khoản liên kết với thẻ độc giả!', 403);
        }

        const { is_read, page, limit } = req.query;
        const result = await notificationsService.getMyNotifications({
            reader_id,
            is_read,
            page: parseInt(page || 1, 10),
            limit: parseInt(limit || 20, 10)
        });

        return sendSuccess(res, 'Lấy danh sách thông báo thành công', result);
    } catch (error) {
        next(error);
    }
};

/**
 * GET /api/notifications/all - Thủ thư/admin xem chung thông báo của độc giả
 */
exports.getAllNotifications = async (req, res, next) => {
    try {
        const { page, limit } = req.query;
        const result = await notificationsService.getAllNotifications({
            page: parseInt(page || 1, 10),
            limit: parseInt(limit || 100, 10)
        });
        return sendSuccess(res, 'Lấy luồng thông báo chung thành công', result);
    } catch (error) {
        next(error);
    }
};

/**
 * 2. GET /api/notifications/unread-count - Đếm số lượng thông báo chưa đọc
 */
exports.getUnreadCount = async (req, res, next) => {
    try {
        const reader_id = req.user.readerId || req.query.reader_id;
        if (!reader_id) {
            return sendError(res, 'Chức năng này chỉ dành cho độc giả!', 403);
        }

        const result = await notificationsService.getUnreadCount({ reader_id });
        return sendSuccess(res, 'Lấy số lượng thông báo chưa đọc thành công', result);
    } catch (error) {
        next(error);
    }
};

/**
 * 3. PUT /api/notifications/:id/read - Đánh dấu 1 thông báo đã đọc
 */
exports.markAsRead = async (req, res, next) => {
    try {
        const notification_id = req.params.id;
        const reader_id = req.user.readerId;

        const result = await notificationsService.markAsRead({ notification_id, reader_id });
        return sendSuccess(res, 'Đánh dấu đã đọc thành công', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 4. PUT /api/notifications/read-all - Đánh dấu tất cả thông báo là đã đọc
 */
exports.markAllAsRead = async (req, res, next) => {
    try {
        const reader_id = req.user.readerId;
        if (!reader_id) {
            return sendError(res, 'Chức năng này chỉ dành cho độc giả!', 403);
        }

        const result = await notificationsService.markAllAsRead({ reader_id });
        return sendSuccess(res, 'Đánh dấu tất cả thông báo là đã đọc thành công', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 5. DELETE /api/notifications/:id - Xóa 1 thông báo
 */
exports.deleteNotification = async (req, res, next) => {
    try {
        const notification_id = req.params.id;
        const reader_id = req.user.readerId;

        const result = await notificationsService.deleteNotification({ notification_id, reader_id });
        return sendSuccess(res, 'Xóa thông báo thành công', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 6. POST /api/notifications/scan-overdue - Thu thu / Admin kich hoat quet va tao thong bao qua han ngay lap tuc
 */
exports.triggerOverdueScan = async (req, res, next) => {
    try {
        const result = await scanAndNotifyOverdue();
        return sendSuccess(res, 'Quét và tạo thông báo quá hạn thành công', result);
    } catch (error) {
        next(error);
    }
};

/**
 * 7. POST /api/notifications/scan-card-expiration - Quét hạn thẻ ngay lập tức
 */
exports.triggerCardExpirationScan = async (req, res, next) => {
    try {
        const result = await scanAndNotifyCardExpiration();
        return sendSuccess(res, 'Quét và tạo thông báo hạn thẻ thành công', result);
    } catch (error) {
        next(error);
    }
};
