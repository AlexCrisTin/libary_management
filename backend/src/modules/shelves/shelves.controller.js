const shelvesService = require('./shelves.service');
const { sendSuccess, sendError } = require('../../utils/response');

/**
 * 1. GET /api/shelves - Lấy danh sách toàn bộ các kệ
 */
exports.getAllShelves = async (req, res, next) => {
    try {
        const shelves = await shelvesService.getAllShelves();
        return sendSuccess(res, 'Lấy danh sách kệ sách thành công', shelves);
    } catch (error) {
        next(error);
    }
};

/**
 * 2. GET /api/shelves/:id - Xem chi tiết một kệ sách
 */
exports.getShelfDetail = async (req, res, next) => {
    try {
        const { id } = req.params;
        const shelf = await shelvesService.getShelfById(id);
        if (!shelf) {
            return sendError(res, 'Không tìm thấy kệ sách này!', 404);
        }
        return sendSuccess(res, 'Lấy chi tiết kệ sách thành công', shelf);
    } catch (error) {
        next(error);
    }
};

/**
 * 3. GET /api/shelves/:id/books - Xem danh sách sách đang nằm trên một kệ
 */
exports.getBooksOnShelf = async (req, res, next) => {
    try {
        const { id } = req.params;
        const books = await shelvesService.getBooksOnShelf(id);
        return sendSuccess(res, 'Lấy danh sách sách trên kệ thành công', books);
    } catch (error) {
        next(error);
    }
};

/**
 * 4. POST /api/shelves - Tạo mới kệ sách
 */
exports.createShelf = async (req, res, next) => {
    try {
        const { floor, section, shelf, capacity } = req.body;
        if (floor === undefined || !section || !shelf) {
            return sendError(res, 'Vui lòng cung cấp đầy đủ Tầng (floor), Khu vực (section) và Kệ số (shelf)!', 400);
        }
        const newShelf = await shelvesService.createShelf(req.body);
        return sendSuccess(res, 'Tạo mới kệ sách thành công', newShelf, 201);
    } catch (error) {
        next(error);
    }
};

/**
 * 5. PUT /api/shelves/:id - Sửa thông tin kệ sách
 */
exports.updateShelf = async (req, res, next) => {
    try {
        const { id } = req.params;
        const updated = await shelvesService.updateShelf(id, req.body);
        if (!updated) {
            return sendError(res, 'Không tìm thấy kệ sách để cập nhật!', 404);
        }
        return sendSuccess(res, 'Cập nhật kệ sách thành công');
    } catch (error) {
        next(error);
    }
};

/**
 * 6. DELETE /api/shelves/:id - Xóa kệ sách
 */
exports.deleteShelf = async (req, res, next) => {
    try {
        const { id } = req.params;
        await shelvesService.deleteShelf(id);
        return sendSuccess(res, 'Xóa kệ sách thành công');
    } catch (error) {
        next(error);
    }
};

/**
 * 7. PUT /api/shelves/assign-book - Xếp sách vào kệ / Chuyển kệ / Loại sách khỏi kệ
 * Hỗ trợ barcode, copy_id, HOẶC bib_id
 */
exports.assignBookToShelf = async (req, res, next) => {
    try {
        const { copy_id, barcode, bib_id, location_id } = req.body;
        if (!copy_id && !barcode && !bib_id) {
            return sendError(res, 'Vui lòng cung cấp copy_id, barcode hoặc bib_id của cuốn sách!', 400);
        }

        const result = await shelvesService.assignBookToShelf({ copy_id, barcode, bib_id, location_id });
        return sendSuccess(res, result.status_message, result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};
