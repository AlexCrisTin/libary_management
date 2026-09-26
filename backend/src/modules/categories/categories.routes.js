const express = require('express');
const router = express.Router();
const categoriesController = require('./categories.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');

// 1. Xem danh sách thể loại sách (Công khai)
router.get('/', categoriesController.getAllCategories);

// 2. Xem chi tiết 1 thể loại (Công khai)
router.get('/:id', categoriesController.getCategoryById);

// 3. Thêm thể loại mới (Chỉ Thủ thư hoặc Admin)
router.post('/', authMiddleware, roleMiddleware('librarian', 'admin'), categoriesController.createCategory);

// 4. Chỉnh sửa thể loại (Chỉ Thủ thư hoặc Admin)
router.put('/:id', authMiddleware, roleMiddleware('librarian', 'admin'), categoriesController.updateCategory);

// 5. Xóa thể loại (Chỉ Thủ thư hoặc Admin)
router.delete('/:id', authMiddleware, roleMiddleware('librarian', 'admin'), categoriesController.deleteCategory);

module.exports = router;
