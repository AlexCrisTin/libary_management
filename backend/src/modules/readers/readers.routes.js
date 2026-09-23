const express = require('express');
const router = express.Router();
const readersController = require('./readers.controller');

const authMiddleware = require('../../middlewares/auth.middleware');

// 1. Xem danh sách độc giả (hỗ trợ tìm kiếm, lọc theo khoa, trạng thái)
router.get('/', readersController.getAllReaders);

// 2. Thêm mới độc giả & Cấp thẻ tại quầy (Thủ thư)
router.post('/', readersController.createReader);

// 3. Quản lý thẻ: Khóa/Mở khóa thẻ hoặc Gia hạn thẻ
router.put('/:id/card', readersController.updateCardStatus);

// 4. Xem danh sách sách đang mượn của độc giả
router.get('/:id/borrowing', readersController.getBorrowingBooks);

// 5. Xem lịch sử mượn trả của độc giả
router.get('/:id/history', readersController.getBorrowHistory);

// 6. Lấy và cập nhật cấu hình sở thích đọc sách của độc giả
router.get('/:id/preferences', authMiddleware, readersController.getReaderPreferences);
router.put('/:id/preferences', authMiddleware, readersController.updateReaderPreferences);

// 7. Xem chi tiết hồ sơ 1 độc giả
router.get('/:id', readersController.getReaderById);

// 7. Chỉnh sửa thông tin độc giả
router.put('/:id', readersController.updateReader);

// 8. Xóa hồ sơ độc giả
router.delete('/:id', readersController.deleteReader);

module.exports = router;
