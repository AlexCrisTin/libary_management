const express = require('express');
const router = express.Router();
const authController = require('./auth.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const { loginLimiter, otpLimiter } = require('../../middlewares/rateLimiter.middleware');

// 1. Đăng ký tài khoản độc giả
router.post('/register', authController.register);

// 2. Đăng nhập (Cả Thủ thư và Độc giả - Có Rate Limiting chống Brute-force)
router.post('/login', loginLimiter, authController.login);

// 3. Lấy thông tin tài khoản đang đăng nhập (Yêu cầu có Token)
router.get('/me', authMiddleware, authController.getMe);

// 3.1. Cập nhật hồ sơ cá nhân (Yêu cầu có Token)
router.put('/profile', authMiddleware, authController.updateProfile);

// 4. Đổi mật khẩu (Yêu cầu có Token)
router.put('/change-password', authMiddleware, authController.changePassword);

// 5. Quên mật khẩu & Đặt lại mật khẩu bằng mã OTP (Có Rate Limiting chống spam OTP)
router.post('/forgot-password', otpLimiter, authController.forgotPassword);
router.post('/reset-password', otpLimiter, authController.resetPassword);

// 6. Đăng xuất (Yêu cầu có Token để thu hồi)
router.post('/logout', authMiddleware, authController.logout);

module.exports = router;
