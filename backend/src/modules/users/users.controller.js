const usersService = require('./users.service');
const { sendSuccess, sendError } = require('../../utils/response');

exports.getAllUsers = async (req, res, next) => {
    try {
        const { role, is_active, keyword, page, limit } = req.query;
        const result = await usersService.getAllUsers({ role, is_active, keyword, page, limit });
        return sendSuccess(res, 'Lấy danh sách tài khoản thành công', result);
    } catch (error) {
        next(error);
    }
};

exports.getUserById = async (req, res, next) => {
    try {
        const { id } = req.params;
        const user = await usersService.getUserById(id);
        if (!user) {
            return sendError(res, 'Không tìm thấy tài khoản này!', 404);
        }
        return sendSuccess(res, 'Lấy chi tiết tài khoản thành công', user);
    } catch (error) {
        next(error);
    }
};

exports.createUser = async (req, res, next) => {
    try {
        const { username, password, role } = req.body;
        if (!username || !password) {
            return sendError(res, 'Vui lòng cung cấp username và password!', 400);
        }
        const newUser = await usersService.createUser(req.body);
        return sendSuccess(res, 'Tạo tài khoản thành công', newUser, 201);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

exports.updateRole = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { role } = req.body;
        if (!role) {
            return sendError(res, 'Vui lòng chọn vai trò mới!', 400);
        }
        const updated = await usersService.updateRole(id, role);
        if (!updated) {
            return sendError(res, 'Không tìm thấy tài khoản để cập nhật!', 404);
        }
        return sendSuccess(res, `Đã chuyển đổi vai trò tài khoản thành ${role} thành công`);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

exports.updateStatus = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { is_active } = req.body;
        if (is_active === undefined) {
            return sendError(res, 'Vui lòng truyền trạng thái is_active (true/false)!', 400);
        }
        const updated = await usersService.updateStatus(id, Boolean(is_active));
        if (!updated) {
            return sendError(res, 'Không tìm thấy tài khoản để cập nhật!', 404);
        }
        return sendSuccess(res, `Đã ${is_active ? 'mở khóa' : 'khóa'} tài khoản thành công`);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

exports.resetPassword = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { newPassword } = req.body;
        if (!newPassword || newPassword.length < 6) {
            return sendError(res, 'Mật khẩu mới phải có tối thiểu 6 ký tự!', 400);
        }
        const updated = await usersService.resetPassword(id, newPassword);
        if (!updated) {
            return sendError(res, 'Không tìm thấy tài khoản!', 404);
        }
        return sendSuccess(res, 'Đặt lại mật khẩu cho tài khoản thành công');
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

exports.deleteUser = async (req, res, next) => {
    try {
        const { id } = req.params;
        await usersService.deleteUser(id);
        return sendSuccess(res, 'Xóa tài khoản thành công');
    } catch (error) {
        next(error);
    }
};
