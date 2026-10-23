const express = require('express');
const router = express.Router();
const notificationsController = require('./notifications.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');

// Tất cả các thao tác thông báo đều yêu cầu đăng nhập
router.use(authMiddleware);

// 1. Đếm số lượng thông báo chưa đọc (đặt trước route /:id)
router.get('/unread-count', roleMiddleware('reader'), notificationsController.getUnreadCount);

// 2. Đánh dấu tất cả thông báo là đã đọc (đặt trước route /:id)
router.put('/read-all', roleMiddleware('reader'), notificationsController.markAllAsRead);

// 3. Trung tâm thông báo nghiệp vụ dành riêng cho Thủ thư / Admin
router.get('/librarian', roleMiddleware('librarian', 'admin'), notificationsController.getLibrarianNotifications);

// API cũ: xem luồng thông báo đã gửi cho toàn bộ độc giả
router.get('/all', roleMiddleware('librarian', 'admin'), notificationsController.getAllNotifications);

// 4. Lấy danh sách thông báo của độc giả
router.get('/', roleMiddleware('reader'), notificationsController.getMyNotifications);

// 5. Đánh dấu 1 thông báo là đã đọc
router.put('/:id/read', roleMiddleware('reader'), notificationsController.markAsRead);

// 6. Xóa 1 thông báo
router.delete('/:id', roleMiddleware('reader'), notificationsController.deleteNotification);

// 7. Quét và tạo thông báo quá hạn & sắp hết hạn ngay lập tức (Thủ thư / Admin)
router.post('/scan-overdue', roleMiddleware('librarian', 'admin'), notificationsController.triggerOverdueScan);

// 8. Quét và tạo thông báo thẻ sắp/hết hạn ngay lập tức (Thủ thư / Admin)
router.post('/scan-card-expiration', roleMiddleware('librarian', 'admin'), notificationsController.triggerCardExpirationScan);

module.exports = router;
