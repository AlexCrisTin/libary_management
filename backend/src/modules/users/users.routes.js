const express = require('express');
const router = express.Router();
const usersController = require('./users.controller');

// 1. Lấy danh sách tài khoản (hỗ trợ lọc theo role, tìm kiếm)
router.get('/', usersController.getAllUsers);

// 2. Tạo tài khoản mới (Tạo Thủ thư hoặc Admin)
router.post('/', usersController.createUser);

// 3. Xem chi tiết 1 tài khoản
router.get('/:id', usersController.getUserById);

// 4. Đổi vai trò tài khoản (Phân quyền)
router.put('/:id/role', usersController.updateRole);

// 5. Khóa hoặc Mở khóa tài khoản
router.put('/:id/status', usersController.updateStatus);

// 6. Đặt lại mật khẩu tài khoản
router.put('/:id/reset-password', usersController.resetPassword);

// 7. Xóa tài khoản
router.delete('/:id', usersController.deleteUser);

module.exports = router;
