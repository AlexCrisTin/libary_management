const { rateLimit } = require('express-rate-limit');
const { sendError } = require('../utils/response');

/**
 * 1. Giới hạn số lần thử đăng nhập (Login Rate Limiter)
 * - Tối đa 5 lần trong 15 phút từ cùng một địa chỉ IP
 * - Trả về mã lỗi 429 Too Many Requests kèm thông điệp tiếng Việt chuẩn hóa
 */
const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 phút
    limit: 5, // Tối đa 5 lượt yêu cầu
    standardHeaders: 'draft-7', // Trả về header RateLimit-Limit, RateLimit-Remaining, RateLimit-Reset
    legacyHeaders: false,
    handler: (req, res) => {
        return sendError(
            res,
            'Bạn đã thử đăng nhập quá 5 lần liên tiếp. Vui lòng thử lại sau 15 phút để bảo vệ an toàn tài khoản!',
            429
        );
    }
});

/**
 * 2. Giới hạn yêu cầu gửi mã OTP và đặt lại mật khẩu (OTP Rate Limiter)
 * - Tối đa 5 lần trong 15 phút để tránh spam OTP hoặc đoán mã xác thực 6 chữ số
 */
const otpLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 phút
    limit: 5,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    handler: (req, res) => {
        return sendError(
            res,
            'Bạn đã thực hiện yêu cầu xác thực OTP quá nhiều lần. Vui lòng thử lại sau 15 phút!',
            429
        );
    }
});

module.exports = {
    loginLimiter,
    otpLimiter
};
