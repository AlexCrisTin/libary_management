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

// 3. Độc giả gửi yêu cầu gia hạn; thủ thư có thể gia hạn trực tiếp
router.post('/renew/:id', circulationController.renewBook);

// 3.1. Thủ thư/admin xem và xử lý các yêu cầu gia hạn
router.get('/renew-requests', roleMiddleware('librarian', 'admin'), circulationController.getRenewalRequests);
router.put('/renew-requests/:id', roleMiddleware('librarian', 'admin'), circulationController.resolveRenewalRequest);

// 4. Lấy danh sách các lượt đang mượn (Độc giả xem của mình, Thủ thư xem toàn bộ hoặc lọc)
router.get('/active', circulationController.getActiveLoans);

// 5. Xem lịch sử mượn trả
router.get('/history', circulationController.getLoanHistory);

// 6. Thu tiền phạt quá hạn (Chỉ Thủ thư hoặc Quản trị viên)
router.put('/:id/pay-fine', roleMiddleware('librarian', 'admin'), circulationController.payFine);

// 7. Ghi nhận sự cố mượn sách: mất, hỏng, quá hạn hoặc lý do khác
router.put('/:id/report', roleMiddleware('librarian', 'admin'), circulationController.reportBookIssue);

// 8. Báo mất sách (giữ tương thích với ứng dụng cũ)
router.put('/:id/lost', roleMiddleware('librarian', 'admin'), circulationController.reportLostBook);

module.exports = router;
