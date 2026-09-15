const express = require('express');
const router = express.Router();
const shelvesController = require('./shelves.controller');

// 1. Lấy danh sách toàn bộ các kệ
router.get('/', shelvesController.getAllShelves);

// 2. Xếp sách vào kệ / Chuyển kệ / Loại khỏi kệ (Đặt trước route /:id)
router.put('/assign-book', shelvesController.assignBookToShelf);

// 3. Xem chi tiết một kệ sách
router.get('/:id', shelvesController.getShelfDetail);

// 4. Xem danh sách các cuốn sách đang nằm trên kệ này
router.get('/:id/books', shelvesController.getBooksOnShelf);

// 5. Thêm kệ sách mới (Thủ thư)
router.post('/', shelvesController.createShelf);

// 6. Cập nhật thông tin kệ sách
router.put('/:id', shelvesController.updateShelf);

// 7. Xóa kệ sách
router.delete('/:id', shelvesController.deleteShelf);

module.exports = router;
