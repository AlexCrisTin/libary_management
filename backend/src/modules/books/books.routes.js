const express = require('express');
const router = express.Router();
const booksController = require('./books.controller');

// 1. Tìm kiếm và lọc sách (Độc giả & Thủ thư)
router.get('/', booksController.searchBooks);

// 2. Cập nhật tình trạng của một bản sao sách (Thủ thư kiểm kê)
router.put('/copies/:copyId', booksController.updateCopyCondition);

// 3. Xem chi tiết một cuốn sách (Độc giả & Thủ thư)
router.get('/:id', booksController.getBookDetail);

// 4. Thêm đầu sách mới (Thủ thư)
router.post('/', booksController.createBook);

// 5. Cập nhật thông tin đầu sách (Thủ thư)
router.put('/:id', booksController.updateBook);

// 6. Xóa đầu sách (Thủ thư)
router.delete('/:id', booksController.deleteBook);

// 7. Lấy danh sách bản sao vật lý của 1 cuốn sách (Thủ thư)
router.get('/:id/copies', booksController.getBookCopies);

// 8. Thêm bản sao vật lý mới cho đầu sách đã có (Thủ thư)
router.post('/:id/copies', booksController.addBookCopy);

module.exports = router;
