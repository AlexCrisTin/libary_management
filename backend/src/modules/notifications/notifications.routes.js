const express = require('express');
const router = express.Router();
const notificationsController = require('./notifications.controller');
const authMiddleware = require('../../middlewares/auth.middleware');

// Tất cả các thao tác thông báo đều yêu cầu đăng nhập
router.use(authMiddleware);

// 1. Đếm số lượng thông báo chưa đọc (đặt trước route /:id)
router.get('/unread-count', notificationsController.getUnreadCount);

// 2. Đánh dấu tất cả thông báo là đã đọc (đặt trước route /:id)
router.put('/read-all', notificationsController.markAllAsRead);

// 3. Lấy danh sách thông báo của độc giả
router.get('/', notificationsController.getMyNotifications);

// 4. Đánh dấu 1 thông báo là đã đọc
router.put('/:id/read', notificationsController.markAsRead);

// 5. Xóa 1 thông báo
router.delete('/:id', notificationsController.deleteNotification);

module.exports = router;
