const express = require('express');
const router = express.Router();
const usersController = require('./users.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');

// Tat ca cac route quan tri user deu can dang nhap va co quyen admin
router.use(authMiddleware, roleMiddleware('admin'));

// 1. Xem danh sach nguoi dung
router.get('/', usersController.getAllUsers);

// 2. Xem chi tiet nguoi dung
router.get('/:id', usersController.getUserById);

// 3. Tao tai khoan thu thu
router.post('/create-librarian', usersController.createLibrarian);

// 4. Khoa / Mo khoa tai khoan
router.put('/:id/status', usersController.updateUserStatus);

// 5. Thay doi vai tro (role)
router.put('/:id/role', usersController.updateUserRole);

// 6. Dat lai mat khau cho tai khoan
router.put('/:id/reset-password', usersController.resetPassword);

module.exports = router;
