const booksService = require('./books.service');
const { sendSuccess, sendError } = require('../../utils/response');

/**
 * 1. GET /api/books - Tìm kiếm & Lọc sách (Độc giả & Thủ thư)
 */
exports.searchBooks = async (req, res, next) => {
    try {
        const {
            keyword,
            ddc_class,
            author,
            subject,
            copy_status,
            language,
            publish_year,
            sort,
            page = 1,
            limit = 10
        } = req.query;
        const result = await booksService.searchBooks({
            keyword,
            ddc_class,
            author,
            subject,
            copy_status,
            language,
            publish_year,
            sort,
            page: parseInt(page, 10),
            limit: parseInt(limit, 10)
        });
        return sendSuccess(res, 'Lấy danh sách sách thành công', result);
    } catch (error) {
        next(error);
    }
};

/**
 * 2. GET /api/books/:id - Xem chi tiết sách & vị trí kệ (Độc giả & Thủ thư)
 */
exports.getBookDetail = async (req, res, next) => {
    try {
        const { id } = req.params;
        const book = await booksService.getBookById(id);

        if (!book) {
            return sendError(res, 'Không tìm thấy cuốn sách này trong thư viện!', 404);
        }

        return sendSuccess(res, 'Lấy chi tiết sách thành công', book);
    } catch (error) {
        next(error);
    }
};

/**
 * 3. POST /api/books - Thêm sách mới (Thủ thư)
 */
exports.createBook = async (req, res, next) => {
    try {
        const { title, isbn } = req.body;

        if (!title || !title.trim()) {
            return sendError(res, 'Tên sách không được để trống!', 400);
        }

        const newBook = await booksService.createBook(req.body);
        return sendSuccess(res, 'Thêm mới sách thành công', newBook, 201);
    } catch (error) {
        next(error);
    }
};

/**
 * 4. PUT /api/books/:id - Cập nhật thông tin sách (Thủ thư)
 */
exports.updateBook = async (req, res, next) => {
    try {
        const { id } = req.params;
        const updated = await booksService.updateBook(id, req.body);

        if (!updated) {
            return sendError(res, 'Không tìm thấy sách để cập nhật!', 404);
        }

        return sendSuccess(res, 'Cập nhật thông tin sách thành công');
    } catch (error) {
        next(error);
    }
};

/**
 * 5. DELETE /api/books/:id - Xóa sách (Thủ thư)
 */
exports.deleteBook = async (req, res, next) => {
    try {
        const { id } = req.params;
        await booksService.deleteBook(id);
        return sendSuccess(res, 'Xóa sách thành công');
    } catch (error) {
        if (error.message && error.message.includes('bản sao được mượn')) {
            return sendError(res, error.message, 400);
        }
        next(error);
    }
};

/**
 * 6. GET /api/books/:id/copies - Lấy danh sách bản sao của 1 cuốn sách (Thủ thư)
 */
exports.getBookCopies = async (req, res, next) => {
    try {
        const { id } = req.params;
        const copies = await booksService.getBookCopies(id);
        return sendSuccess(res, 'Lấy danh sách bản sao thành công', copies);
    } catch (error) {
        next(error);
    }
};

/**
 * 7. PUT /api/books/copies/:copyId - Cập nhật tình trạng bản sao (Thủ thư đi kiểm kê tại giá)
 */
exports.updateCopyCondition = async (req, res, next) => {
    try {
        const { copyId } = req.params;
        const { condition, status, location_id } = req.body;

        const updated = await booksService.updateCopyCondition(copyId, { condition, status, location_id });
        if (!updated) {
            return sendError(res, 'Không tìm thấy bản sao sách để cập nhật!', 404);
        }

        return sendSuccess(res, 'Cập nhật tình trạng bản sao sách thành công');
    } catch (error) {
        next(error);
    }
};

/**
 * DELETE /api/books/copies/:copyId - Xóa riêng một bản sao chưa phát sinh giao dịch
 */
exports.deleteCopy = async (req, res, next) => {
    try {
        const deleted = await booksService.deleteCopy(req.params.copyId);
        if (!deleted) {
            return sendError(res, 'Không tìm thấy bản sao sách để xóa!', 404);
        }
        return sendSuccess(res, 'Xóa bản sao sách thành công', deleted);
    } catch (error) {
        if (error.code === 'COPY_IN_USE' || error.code === 'COPY_HAS_HISTORY') {
            return sendError(res, error.message, 409);
        }
        next(error);
    }
};

/**
 * 8. POST /api/books/:id/copies - Thêm bản sao vật lý mới cho đầu sách
 */
exports.addBookCopy = async (req, res, next) => {
    try {
        const { id } = req.params;
        const newCopy = await booksService.addCopy(id, req.body);
        return sendSuccess(res, 'Thêm bản sao sách thành công', newCopy, 201);
    } catch (error) {
        next(error);
    }
};

/**
 * 9. GET /api/books/scan/:code - Quét trực tiếp Barcode/ISBN để tìm sách & vị trí kệ
 */
exports.scanBook = async (req, res, next) => {
    try {
        const { code } = req.params;
        if (!code || !code.trim()) {
            return sendError(res, 'Vui lòng cung cấp mã barcode hoặc ISBN cần quét!', 400);
        }

        const result = await booksService.scanBookByCode(code.trim());
        if (!result) {
            return sendError(res, 'Không tìm thấy sách hoặc bản sao nào trong thư viện khớp với mã vừa quét!', 404);
        }

        return sendSuccess(res, 'Quét mã thành công', result);
    } catch (error) {
        next(error);
    }
};

/**
 * 10. GET /api/books/lookup-isbn/:isbn - Tra cứu thông tin sách thật trên Internet qua ISBN
 */
exports.lookupIsbn = async (req, res, next) => {
    try {
        const { isbn } = req.params;
        if (!isbn || !isbn.trim()) {
            return sendError(res, 'Vui lòng cung cấp mã ISBN cần tra cứu!', 400);
        }

        const result = await booksService.lookupBookByIsbn(isbn.trim());
        return sendSuccess(res, 'Tra cứu thông tin sách thành công', result);
    } catch (error) {
        return sendError(res, error.message, 404);
    }
};

exports.getBookmark = async (req, res, next) => {
    try {
        const bookmarked = await booksService.getBookmark({
            reader_id: req.user.readerId,
            bib_id: req.params.id
        });
        return sendSuccess(res, 'Lấy trạng thái lưu sách thành công', { bookmarked });
    } catch (error) {
        next(error);
    }
};

exports.addBookmark = async (req, res, next) => {
    try {
        const result = await booksService.addBookmark({
            reader_id: req.user.readerId,
            bib_id: req.params.id
        });
        if (!result) return sendError(res, 'Không tìm thấy sách để lưu!', 404);
        return sendSuccess(res, 'Đã lưu sách', result, 201);
    } catch (error) {
        next(error);
    }
};

exports.removeBookmark = async (req, res, next) => {
    try {
        const result = await booksService.removeBookmark({
            reader_id: req.user.readerId,
            bib_id: req.params.id
        });
        return sendSuccess(res, 'Đã bỏ lưu sách', result);
    } catch (error) {
        next(error);
    }
};
