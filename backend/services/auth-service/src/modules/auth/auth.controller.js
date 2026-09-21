const authService = require('./auth.service');
const { sendSuccess, sendError } = require('../../utils/response');

/**
 * 1. POST /api/auth/register - Dang ky tai khoan
 */
exports.register = async (req, res, next) => {
    try {
        const { username, password } = req.body;

        if (!username || !username.trim()) {
            return sendError(res, 'Ten dang nhap khong duoc de trong!', 400);
        }
        if (!password || password.length < 6) {
            return sendError(res, 'Mat khau phai co it nhat 6 ky tu!', 400);
        }

        const result = await authService.register({ username, password });
        return sendSuccess(res, 'Dang ky tai khoan thanh cong', result, 201);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 2. POST /api/auth/login - Dang nhap
 */
exports.login = async (req, res, next) => {
    try {
        const { username, password } = req.body;

        if (!username || !password) {
            return sendError(res, 'Vui long nhap day du tai khoan va mat khau!', 400);
        }

        const result = await authService.login({ username, password });
        return sendSuccess(res, 'Dang nhap thanh cong', result);
    } catch (error) {
        return sendError(res, error.message, 401);
    }
};

/**
 * 3. GET /api/auth/me - Lay thong tin tai khoan hien tai
 */
exports.getMe = async (req, res, next) => {
    try {
        const result = await authService.getMe(req.user.userId);
        return sendSuccess(res, 'Lay thong tin tai khoan thanh cong', result);
    } catch (error) {
        next(error);
    }
};

/**
 * 4. PUT /api/auth/change-password - Doi mat khau
 */
exports.changePassword = async (req, res, next) => {
    try {
        const { old_password, new_password } = req.body;

        if (!old_password || !new_password) {
            return sendError(res, 'Vui long nhap day du mat khau cu va mat khau moi!', 400);
        }
        if (new_password.length < 6) {
            return sendError(res, 'Mat khau moi phai co it nhat 6 ky tu!', 400);
        }

        const result = await authService.changePassword({
            userId: req.user.userId,
            old_password,
            new_password
        });
        return sendSuccess(res, 'Doi mat khau thanh cong', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};
