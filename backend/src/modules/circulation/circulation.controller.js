const circulationService = require('./circulation.service');
const { sendSuccess, sendError } = require('../../utils/response');

/**
 * 1. POST /api/circulation/borrow - Cho mượn sách (Thủ thư/Admin)
 */
exports.borrowBook = async (req, res, next) => {
    try {
        const { reader_id, reader_code, copy_id, barcode, due_days } = req.body;

        if (!reader_id && !reader_code) {
            return sendError(res, 'Vui lòng cung cấp mã thẻ độc giả hoặc ID độc giả!', 400);
        }
        if (!copy_id && !barcode) {
            return sendError(res, 'Vui lòng quét mã vạch hoặc cung cấp ID cuốn sách!', 400);
        }

        const issued_by = req.user ? req.user.userId : null;

        const result = await circulationService.borrowBook({
            reader_id,
            reader_code,
            copy_id,
            barcode,
            due_days: due_days ? parseInt(due_days, 10) : 14,
            issued_by
        });

        return sendSuccess(res, 'Cho mượn sách thành công', result, 201);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 2. POST /api/circulation/return - Nhận trả sách (Thủ thư/Admin)
 */
exports.returnBook = async (req, res, next) => {
    try {
        const { barcode, copy_id, tx_id, condition, fine_rate_per_day } = req.body;

        if (!barcode && !copy_id && !tx_id) {
            return sendError(res, 'Vui lòng quét mã vạch sách hoặc mã giao dịch để trả sách!', 400);
        }

        const returned_to = req.user ? req.user.userId : null;

        const result = await circulationService.returnBook({
            barcode,
            copy_id,
            tx_id,
            returned_to,
            condition,
            fine_rate_per_day: fine_rate_per_day ? parseInt(fine_rate_per_day, 10) : 2000
        });

        return sendSuccess(res, 'Nhận trả sách thành công', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 3. POST /api/circulation/renew/:id - Gia hạn mượn sách (Độc giả hoặc Thủ thư)
 */
exports.renewBook = async (req, res, next) => {
    try {
        const tx_id = req.params.id;
        const { extend_days } = req.body;

        const user_role = req.user.role;
        const reader_id = req.user.readerId; // Có nếu là độc giả đăng nhập

        const result = await circulationService.renewBook({
            tx_id,
            reader_id,
            user_role,
            extend_days: extend_days ? parseInt(extend_days, 10) : 7
        });

        return sendSuccess(res, 'Gia hạn mượn sách thành công', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 4. GET /api/circulation/active - Xem danh sách các lượt đang mượn
 */
exports.getActiveLoans = async (req, res, next) => {
    try {
        let { reader_id, keyword, status, page, limit } = req.query;

        // Nếu người gọi là độc giả, chỉ cho phép xem sách của chính họ
        if (req.user.role === 'reader') {
            reader_id = req.user.readerId;
        }

        const result = await circulationService.getActiveLoans({
            reader_id,
            keyword,
            status,
            page: parseInt(page || 1, 10),
            limit: parseInt(limit || 10, 10)
        });

        return sendSuccess(res, 'Lấy danh sách sách đang mượn thành công', result);
    } catch (error) {
        next(error);
    }
};

/**
 * 5. GET /api/circulation/history - Xem lịch sử mượn trả
 */
exports.getLoanHistory = async (req, res, next) => {
    try {
        let { reader_id, copy_id, status, from_date, to_date, page, limit } = req.query;

        // Nếu người gọi là độc giả, chỉ cho phép xem lịch sử của chính họ
        if (req.user.role === 'reader') {
            reader_id = req.user.readerId;
        }

        const result = await circulationService.getLoanHistory({
            reader_id,
            copy_id,
            status,
            from_date,
            to_date,
            page: parseInt(page || 1, 10),
            limit: parseInt(limit || 10, 10)
        });

        return sendSuccess(res, 'Lấy lịch sử mượn trả thành công', result);
    } catch (error) {
        next(error);
    }
};

/**
 * 6. PUT /api/circulation/:id/pay-fine - Thu tiền phạt quá hạn (Thủ thư/Admin)
 */
exports.payFine = async (req, res, next) => {
    try {
        const tx_id = req.params.id;
        const result = await circulationService.payFine({ tx_id });
        return sendSuccess(res, 'Thanh toán tiền phạt thành công', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 7. PUT /api/circulation/:id/lost - Báo mất sách (Thủ thư/Admin)
 */
exports.reportLostBook = async (req, res, next) => {
    try {
        const tx_id = req.params.id;
        const result = await circulationService.reportLostBook({ tx_id });
        return sendSuccess(res, 'Ghi nhận mất sách thành công', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};
