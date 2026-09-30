const express = require('express');
const router = express.Router();
const readersController = require('./readers.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');

// Tất cả các thao tác liên quan đến độc giả đều bắt buộc phải đăng nhập
router.use(authMiddleware);

// Middleware kiểm tra: Chỉ Thủ thư, Admin hoặc chính Độc giả đó mới có quyền truy cập
const readerOrStaffMiddleware = (req, res, next) => {
    if (['librarian', 'admin'].includes(req.user.role)) {
        return next();
    }
    const targetId = req.params.id;
    if (req.user.readerId && (targetId === req.user.readerId || targetId === 'me')) {
        return next();
    }
    return res.status(403).json({
        status: 'error',
        message: 'Bạn không có quyền truy cập thông tin của độc giả khác!'
    });
};

// 1. Xem danh sách độc giả (Chỉ Thủ thư hoặc Admin)
router.get('/', roleMiddleware('librarian', 'admin'), readersController.getAllReaders);

// 2. Thêm mới độc giả & Cấp thẻ tại quầy (Chỉ Thủ thư hoặc Admin)
router.post('/', roleMiddleware('librarian', 'admin'), readersController.createReader);

// 3. Quản lý thẻ: Khóa/Mở khóa thẻ hoặc Gia hạn thẻ (Chỉ Thủ thư hoặc Admin)
router.put('/:id/card', roleMiddleware('librarian', 'admin'), readersController.updateCardStatus);

// 4. Xem danh sách sách đang mượn của độc giả (Chính độc giả đó hoặc Thủ thư/Admin)
router.get('/:id/borrowing', readerOrStaffMiddleware, readersController.getBorrowingBooks);

// 5. Xem lịch sử mượn trả của độc giả (Chính độc giả đó hoặc Thủ thư/Admin)
router.get('/:id/history', readerOrStaffMiddleware, readersController.getBorrowHistory);

// 6. Lấy và cập nhật cấu hình sở thích đọc sách của độc giả (Chính độc giả đó hoặc Thủ thư/Admin)
router.get('/:id/preferences', readerOrStaffMiddleware, readersController.getReaderPreferences);
router.put('/:id/preferences', readerOrStaffMiddleware, readersController.updateReaderPreferences);

// 7. Xem chi tiết hồ sơ 1 độc giả (Chính độc giả đó hoặc Thủ thư/Admin)
router.get('/:id', readerOrStaffMiddleware, readersController.getReaderById);

// 8. Chỉnh sửa thông tin độc giả (Chỉ Thủ thư hoặc Admin)
router.put('/:id', roleMiddleware('librarian', 'admin'), readersController.updateReader);

// 9. Xóa hồ sơ độc giả (Chỉ Thủ thư hoặc Admin)
router.delete('/:id', roleMiddleware('librarian', 'admin'), readersController.deleteReader);

module.exports = router;
