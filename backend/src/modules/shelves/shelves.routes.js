const express = require('express');
const router = express.Router();
const shelvesController = require('./shelves.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');

// 1. Lấy danh sách toàn bộ các kệ (Công khai)
router.get('/', shelvesController.getAllShelves);

// 2. Xếp sách vào kệ / Chuyển kệ / Loại khỏi kệ (Chỉ Thủ thư hoặc Admin)
router.put('/assign-book', authMiddleware, roleMiddleware('librarian', 'admin'), shelvesController.assignBookToShelf);

// 3. Xem chi tiết một kệ sách (Công khai)
router.get('/:id', shelvesController.getShelfDetail);

// 4. Xem danh sách các cuốn sách đang nằm trên kệ này (Công khai)
router.get('/:id/books', shelvesController.getBooksOnShelf);

// 5. Thêm kệ sách mới (Chỉ Thủ thư hoặc Admin)
router.post('/', authMiddleware, roleMiddleware('librarian', 'admin'), shelvesController.createShelf);

// 6. Cập nhật thông tin kệ sách (Chỉ Thủ thư hoặc Admin)
router.put('/:id', authMiddleware, roleMiddleware('librarian', 'admin'), shelvesController.updateShelf);

// 7. Xóa kệ sách (Chỉ Thủ thư hoặc Admin)
router.delete('/:id', authMiddleware, roleMiddleware('librarian', 'admin'), shelvesController.deleteShelf);

module.exports = router;
