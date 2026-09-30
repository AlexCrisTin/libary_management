const express = require('express');
const router = express.Router();
const booksController = require('./books.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');

// 1. Tìm kiếm và lọc sách (Công khai cho Độc giả & Thủ thư)
router.get('/', booksController.searchBooks);

// 2. Cập nhật tình trạng của một bản sao sách (Thủ thư kiểm kê)
router.put('/copies/:copyId', authMiddleware, roleMiddleware('librarian', 'admin'), booksController.updateCopyCondition);

// 3. Quét trực tiếp Barcode/ISBN để tìm sách & vị trí kệ (Công khai)
router.get('/scan/:code', booksController.scanBook);

// 4. Tra cứu thông tin sách thật trên Internet qua ISBN (Google Books & Open Library)
router.get('/lookup-isbn/:isbn', booksController.lookupIsbn);

// 5. Xem chi tiết một cuốn sách (Công khai)
router.get('/:id', booksController.getBookDetail);

// 6. Thêm đầu sách mới (Chỉ Thủ thư hoặc Admin)
router.post('/', authMiddleware, roleMiddleware('librarian', 'admin'), booksController.createBook);

// 7. Cập nhật thông tin đầu sách (Chỉ Thủ thư hoặc Admin)
router.put('/:id', authMiddleware, roleMiddleware('librarian', 'admin'), booksController.updateBook);

// 8. Xóa đầu sách (Chỉ Thủ thư hoặc Admin)
router.delete('/:id', authMiddleware, roleMiddleware('librarian', 'admin'), booksController.deleteBook);

// 9. Lấy danh sách bản sao vật lý của 1 cuốn sách (Chỉ Thủ thư hoặc Admin)
router.get('/:id/copies', authMiddleware, roleMiddleware('librarian', 'admin'), booksController.getBookCopies);

// 10. Thêm bản sao vật lý mới cho đầu sách đã có (Chỉ Thủ thư hoặc Admin)
router.post('/:id/copies', authMiddleware, roleMiddleware('librarian', 'admin'), booksController.addBookCopy);

module.exports = router;
