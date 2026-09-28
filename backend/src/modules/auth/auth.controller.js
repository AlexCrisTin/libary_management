const authService = require('./auth.service');
const { sendSuccess, sendError } = require('../../utils/response');

/**
 * 1. POST /api/auth/register - Đăng ký độc giả mới
 */
exports.register = async (req, res, next) => {
    try {
        const { username, password, full_name } = req.body;
        if (!username || !password || !full_name) {
            return sendError(res, 'Vui lòng cung cấp đầy đủ tên đăng nhập, mật khẩu và họ tên!', 400);
        }

        const result = await authService.register(req.body);
        return sendSuccess(res, 'Đăng ký tài khoản thành công', result, 201);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 2. POST /api/auth/login - Đăng nhập (Thủ thư & Độc giả)
 */
exports.login = async (req, res, next) => {
    try {
        const { username, password } = req.body;
        if (!username || !password) {
            return sendError(res, 'Vui lòng nhập tên đăng nhập và mật khẩu!', 400);
        }

        const result = await authService.login({ username, password });
        return sendSuccess(res, 'Đăng nhập thành công', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 3. GET /api/auth/me - Lấy thông tin tài khoản hiện tại (Dữ liệu thời gian thực từ DB)
 */
exports.getMe = async (req, res, next) => {
    try {
        const user = await authService.getMe(req.user.userId);
        return sendSuccess(res, 'Lấy thông tin tài khoản thành công', user);
    } catch (error) {
        next(error);
    }
};

/**
 * 3.1. PUT /api/auth/profile - Cập nhật thông tin hồ sơ cá nhân
 */
exports.updateProfile = async (req, res, next) => {
    try {
        const updatedUser = await authService.updateProfile(req.user.userId, req.body);
        return sendSuccess(res, 'Cập nhật hồ sơ cá nhân thành công', updatedUser);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 4. PUT /api/auth/change-password - Đổi mật khẩu
 */
exports.changePassword = async (req, res, next) => {
    try {
        const { oldPassword, newPassword } = req.body;
        if (!oldPassword || !newPassword) {
            return sendError(res, 'Vui lòng nhập mật khẩu cũ và mật khẩu mới!', 400);
        }
        if (newPassword.length < 6) {
            return sendError(res, 'Mật khẩu mới phải có tối thiểu 6 ký tự!', 400);
        }

        await authService.changePassword(req.user.userId, { oldPassword, newPassword });
        return sendSuccess(res, 'Đổi mật khẩu thành công!');
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 5. POST /api/auth/forgot-password - Yêu cầu mã OTP quên mật khẩu
 */
exports.forgotPassword = async (req, res, next) => {
    try {
        const { email } = req.body;
        if (!email) {
            return sendError(res, 'Vui lòng cung cấp địa chỉ email!', 400);
        }

        const result = await authService.forgotPassword({ email });
        return sendSuccess(res, 'Mã OTP đặt lại mật khẩu đã được tạo thành công', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 6. POST /api/auth/reset-password - Đặt lại mật khẩu bằng mã OTP
 */
exports.resetPassword = async (req, res, next) => {
    try {
        const { email, otp, new_password } = req.body;
        if (!email || !otp || !new_password) {
            return sendError(res, 'Vui lòng cung cấp đầy đủ email, mã OTP và mật khẩu mới!', 400);
        }

        const result = await authService.resetPassword({ email, otp, new_password });
        return sendSuccess(res, result.message, result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 7. POST /api/auth/logout - Đăng xuất (Vô hiệu hóa Token)
 */
exports.logout = async (req, res, next) => {
    try {
        const token = req.token || req.headers.authorization?.split(' ')[1];
        const result = await authService.logout({ token, user: req.user });
        return sendSuccess(res, result.message, null);
    } catch (error) {
        next(error);
    }
};

