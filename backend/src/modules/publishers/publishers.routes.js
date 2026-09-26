const express = require('express');
const router = express.Router();
const publishersController = require('./publishers.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');

// 1. Xem danh sách nhà xuất bản (Công khai)
router.get('/', publishersController.getAllPublishers);

// 2. Xem chi tiết 1 nhà xuất bản (Công khai)
router.get('/:id', publishersController.getPublisherById);

// 3. Thêm nhà xuất bản mới (Chỉ Thủ thư hoặc Admin)
router.post('/', authMiddleware, roleMiddleware('librarian', 'admin'), publishersController.createPublisher);

// 4. Chỉnh sửa thông tin nhà xuất bản (Chỉ Thủ thư hoặc Admin)
router.put('/:id', authMiddleware, roleMiddleware('librarian', 'admin'), publishersController.updatePublisher);

// 5. Xóa nhà xuất bản (Chỉ Thủ thư hoặc Admin)
router.delete('/:id', authMiddleware, roleMiddleware('librarian', 'admin'), publishersController.deletePublisher);

module.exports = router;
