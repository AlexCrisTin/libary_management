const usersService = require('./users.service');
const { sendSuccess, sendError } = require('../../utils/response');

/**
 * 1. GET /api/users - Lay danh sach nguoi dung
 */
exports.getAllUsers = async (req, res, next) => {
    try {
        const { keyword, role, is_active, page, limit } = req.query;
        const result = await usersService.getAllUsers({
            keyword,
            role,
            is_active,
            page: parseInt(page || 1, 10),
            limit: parseInt(limit || 10, 10)
        });
        return sendSuccess(res, 'Lay danh sach nguoi dung thanh cong', result);
    } catch (error) {
        next(error);
    }
};

/**
 * 2. GET /api/users/:id - Lay chi tiet nguoi dung
 */
exports.getUserById = async (req, res, next) => {
    try {
        const { id } = req.params;
        const user = await usersService.getUserById(id);
        if (!user) {
            return sendError(res, 'Khong tim thay nguoi dung!', 404);
        }
        return sendSuccess(res, 'Lay chi tiet nguoi dung thanh cong', user);
    } catch (error) {
        next(error);
    }
};

/**
 * 3. POST /api/users/create-librarian - Tao tai khoan thu thu
 */
exports.createLibrarian = async (req, res, next) => {
    try {
        const { username, password } = req.body;
        if (!username || !password) {
            return sendError(res, 'Vui long nhap day du tai khoan va mat khau!', 400);
        }
        if (password.length < 6) {
            return sendError(res, 'Mat khau phai co it nhat 6 ky tu!', 400);
        }

        const result = await usersService.createLibrarian({ username, password });
        return sendSuccess(res, 'Tao tai khoan thu thu thanh cong', result, 201);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 4. PUT /api/users/:id/status - Khoa/Mo khoa tai khoan
 */
exports.updateUserStatus = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { is_active } = req.body;

        if (is_active === undefined) {
            return sendError(res, 'Vui long cung cap trang thai is_active (true/false)!', 400);
        }

        const result = await usersService.updateUserStatus(id, Boolean(is_active));
        return sendSuccess(res, result.message, result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 5. PUT /api/users/:id/role - Doi vai tro
 */
exports.updateUserRole = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { role } = req.body;

        if (!role) {
            return sendError(res, 'Vui long cung cap vai tro role!', 400);
        }

        const result = await usersService.updateUserRole(id, role);
        return sendSuccess(res, result.message, result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 6. PUT /api/users/:id/reset-password - Dat lai mat khau
 */
exports.resetPassword = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { new_password } = req.body;

        if (!new_password || new_password.length < 6) {
            return sendError(res, 'Mat khau moi phai co it nhat 6 ky tu!', 400);
        }

        const result = await usersService.resetPassword(id, new_password);
        return sendSuccess(res, result.message, result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};
