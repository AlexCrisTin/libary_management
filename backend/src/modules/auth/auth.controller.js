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
 * 3. GET /api/auth/me - Lấy thông tin tài khoản hiện tại
 */
exports.getMe = async (req, res, next) => {
    try {
        return sendSuccess(res, 'Lấy thông tin tài khoản thành công', req.user);
    } catch (error) {
        next(error);
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
