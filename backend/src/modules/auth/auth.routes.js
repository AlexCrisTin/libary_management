const express = require('express');
const router = express.Router();
const authController = require('./auth.controller');
const authMiddleware = require('../../middlewares/auth.middleware');

// 1. Đăng ký tài khoản độc giả
router.post('/register', authController.register);

// 2. Đăng nhập (Cả Thủ thư và Độc giả)
router.post('/login', authController.login);

// 3. Lấy thông tin tài khoản đang đăng nhập (Yêu cầu có Token)
router.get('/me', authMiddleware, authController.getMe);

// 4. Đổi mật khẩu (Yêu cầu có Token)
router.put('/change-password', authMiddleware, authController.changePassword);

module.exports = router;
