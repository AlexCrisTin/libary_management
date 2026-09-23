const readersService = require('./readers.service');
const { sendSuccess, sendError } = require('../../utils/response');

/**
 * 1. GET /api/readers - Xem danh sách độc giả (Thủ thư)
 */
exports.getAllReaders = async (req, res, next) => {
    try {
        const { keyword, reader_type, status, page, limit } = req.query;
        const result = await readersService.getAllReaders({
            keyword,
            reader_type,
            status,
            page: parseInt(page || 1, 10),
            limit: parseInt(limit || 10, 10)
        });
        return sendSuccess(res, 'Lấy danh sách độc giả thành công', result);
    } catch (error) {
        next(error);
    }
};

/**
 * 2. GET /api/readers/:id - Xem chi tiết hồ sơ độc giả
 */
exports.getReaderById = async (req, res, next) => {
    try {
        const { id } = req.params;
        const reader = await readersService.getReaderById(id);
        if (!reader) {
            return sendError(res, 'Không tìm thấy hồ sơ độc giả này!', 404);
        }
        return sendSuccess(res, 'Lấy chi tiết độc giả thành công', reader);
    } catch (error) {
        next(error);
    }
};

/**
 * 3. POST /api/readers - Thêm độc giả mới & Cấp thẻ tại quầy (Thủ thư)
 */
exports.createReader = async (req, res, next) => {
    try {
        const { full_name } = req.body;
        if (!full_name || !full_name.trim()) {
            return sendError(res, 'Họ và tên độc giả không được để trống!', 400);
        }

        const newReader = await readersService.createReader(req.body);
        return sendSuccess(res, 'Thêm độc giả và cấp thẻ thành công', newReader, 201);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 4. PUT /api/readers/:id - Sửa thông tin độc giả (Thủ thư)
 */
exports.updateReader = async (req, res, next) => {
    try {
        const { id } = req.params;
        const updated = await readersService.updateReader(id, req.body);
        if (!updated) {
            return sendError(res, 'Không tìm thấy độc giả để cập nhật!', 404);
        }
        return sendSuccess(res, 'Cập nhật thông tin độc giả thành công');
    } catch (error) {
        next(error);
    }
};

/**
 * 5. PUT /api/readers/:id/card - Quản lý thẻ: Khóa/Mở khóa hoặc Gia hạn (Thủ thư)
 */
exports.updateCardStatus = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { status, card_expired } = req.body;

        if (!status && !card_expired) {
            return sendError(res, 'Vui lòng truyền status (active/suspended/expired) hoặc ngày hết hạn mới (card_expired)!', 400);
        }

        const updated = await readersService.updateCardStatus(id, { status, card_expired });
        if (!updated) {
            return sendError(res, 'Không tìm thấy độc giả để cập nhật thẻ!', 404);
        }

        return sendSuccess(res, 'Cập nhật trạng thái thẻ thư viện thành công');
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 6. DELETE /api/readers/:id - Xóa hồ sơ độc giả
 */
exports.deleteReader = async (req, res, next) => {
    try {
        const { id } = req.params;
        await readersService.deleteReader(id);
        return sendSuccess(res, 'Xóa độc giả thành công');
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 7. GET /api/readers/:id/borrowing - Xem danh sách sách đang mượn của 1 độc giả
 */
exports.getBorrowingBooks = async (req, res, next) => {
    try {
        const { id } = req.params;
        const books = await readersService.getBorrowingBooks(id);
        return sendSuccess(res, 'Lấy danh sách sách đang mượn thành công', books);
    } catch (error) {
        next(error);
    }
};

/**
 * 8. GET /api/readers/:id/history - Xem toàn bộ lịch sử mượn trả
 */
exports.getBorrowHistory = async (req, res, next) => {
    try {
        const { id } = req.params;
        const history = await readersService.getBorrowHistory(id);
        return sendSuccess(res, 'Lấy lịch sử mượn trả thành công', history);
    } catch (error) {
        next(error);
    }
};

/**
 * 9. GET /api/readers/:id/preferences - Lấy cấu hình sở thích đọc sách của độc giả
 */
exports.getReaderPreferences = async (req, res, next) => {
    try {
        const readerId = req.params.id === 'me' && req.user ? req.user.readerId : req.params.id;
        const preferences = await readersService.getReaderPreferences(readerId);
        return sendSuccess(res, 'Lấy sở thích độc giả thành công', preferences);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 10. PUT /api/readers/:id/preferences - Cập nhật cấu hình sở thích đọc sách của độc giả
 */
exports.updateReaderPreferences = async (req, res, next) => {
    try {
        const readerId = req.params.id === 'me' && req.user ? req.user.readerId : req.params.id;
        const updated = await readersService.updateReaderPreferences(readerId, req.body);
        return sendSuccess(res, 'Cập nhật sở thích độc giả thành công', updated);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

