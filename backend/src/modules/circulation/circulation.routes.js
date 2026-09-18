const express = require('express');
const router = express.Router();
const circulationController = require('./circulation.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');

// Tất cả các route mượn trả đều yêu cầu đăng nhập
router.use(authMiddleware);

// 1. Cho mượn sách (Chỉ Thủ thư hoặc Quản trị viên)
router.post('/borrow', roleMiddleware('librarian', 'admin'), circulationController.borrowBook);

// 2. Nhận trả sách (Chỉ Thủ thư hoặc Quản trị viên)
router.post('/return', roleMiddleware('librarian', 'admin'), circulationController.returnBook);

// 3. Gia hạn mượn sách (Độc giả tự gia hạn hoặc Thủ thư thao tác)
router.post('/renew/:id', circulationController.renewBook);

// 4. Lấy danh sách các lượt đang mượn (Độc giả xem của mình, Thủ thư xem toàn bộ hoặc lọc)
router.get('/active', circulationController.getActiveLoans);

// 5. Xem lịch sử mượn trả
router.get('/history', circulationController.getLoanHistory);

// 6. Thu tiền phạt quá hạn (Chỉ Thủ thư hoặc Quản trị viên)
router.put('/:id/pay-fine', roleMiddleware('librarian', 'admin'), circulationController.payFine);

// 7. Báo mất sách (Chỉ Thủ thư hoặc Quản trị viên)
router.put('/:id/lost', roleMiddleware('librarian', 'admin'), circulationController.reportLostBook);

module.exports = router;
