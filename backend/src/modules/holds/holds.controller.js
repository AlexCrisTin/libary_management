const holdsService = require('./holds.service');
const { sendSuccess, sendError } = require('../../utils/response');

/**
 * 1. POST /api/holds - Đặt trước đầu sách
 */
exports.createHold = async (req, res, next) => {
    try {
        const { bib_id } = req.body;
        if (!bib_id) {
            return sendError(res, 'Vui lòng cung cấp mã đầu sách (bib_id)!', 400);
        }

        // Nếu là độc giả đăng nhập, lấy trực tiếp readerId từ token
        const reader_id = req.user.role === 'reader' ? req.user.readerId : (req.body.reader_id || req.user.readerId);
        if (!reader_id) {
            return sendError(res, 'Vui lòng cung cấp mã ID độc giả (reader_id)!', 400);
        }

        const result = await holdsService.createHold({ reader_id, bib_id });
        return sendSuccess(res, 'Đặt trước đầu sách thành công', result, 201);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 2. GET /api/holds/my-holds - Độc giả xem các lượt đặt trước của mình
 */
exports.getMyHolds = async (req, res, next) => {
    try {
        const reader_id = req.user.readerId;
        if (!reader_id) {
            return sendError(res, 'Tài khoản này không liên kết với hồ sơ độc giả nào!', 403);
        }

        const { status } = req.query;
        const result = await holdsService.getMyHolds({ reader_id, status });
        return sendSuccess(res, 'Lấy danh sách sách đặt trước thành công', result);
    } catch (error) {
        next(error);
    }
};

/**
 * 3. GET /api/holds - Thủ thư xem toàn bộ danh sách đặt trước trong thư viện
 */
exports.getAllHolds = async (req, res, next) => {
    try {
        const { bib_id, reader_id, status, page, limit } = req.query;
        const result = await holdsService.getAllHolds({
            bib_id,
            reader_id,
            status,
            page: parseInt(page || 1, 10),
            limit: parseInt(limit || 10, 10)
        });
        return sendSuccess(res, 'Lấy danh sách hàng đợi đặt trước thành công', result);
    } catch (error) {
        next(error);
    }
};

/**
 * 4. PUT /api/holds/:id/cancel - Hủy yêu cầu đặt trước
 */
exports.cancelHold = async (req, res, next) => {
    try {
        const hold_id = req.params.id;
        const reader_id = req.user.readerId;
        const user_role = req.user.role;

        const result = await holdsService.cancelHold({ hold_id, reader_id, user_role });
        return sendSuccess(res, 'Hủy yêu cầu đặt trước thành công', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};
