const express = require('express');
const router = express.Router();
const holdsController = require('./holds.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');

// Tất cả các thao tác đặt trước đều yêu cầu đăng nhập
router.use(authMiddleware);

// 1. Độc giả xem danh sách các cuốn sách mình đang đặt trước
router.get('/my-holds', holdsController.getMyHolds);

// 2. Đặt trước một đầu sách
router.post('/', holdsController.createHold);

// 3. Thủ thư / Quản trị viên xem toàn bộ danh sách đặt trước
router.get('/', roleMiddleware('librarian', 'admin'), holdsController.getAllHolds);

// 4. Hủy yêu cầu đặt trước (Độc giả tự hủy hoặc Thủ thư hủy giúp)
router.put('/:id/cancel', holdsController.cancelHold);

module.exports = router;
