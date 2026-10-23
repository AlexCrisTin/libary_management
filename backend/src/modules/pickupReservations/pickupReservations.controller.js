const service = require('./pickupReservations.service');
const { sendSuccess, sendError } = require('../../utils/response');

exports.create = async (req, res) => {
    try {
        if (!req.user.readerId) return sendError(res, 'Tài khoản chưa liên kết hồ sơ độc giả!', 403);
        if (!req.body.bib_id) return sendError(res, 'Vui lòng cung cấp mã đầu sách!', 400);
        const result = await service.createReservation({
            reader_id: req.user.readerId,
            bib_id: req.body.bib_id,
            hold_id: req.body.hold_id || null
        });
        return sendSuccess(res, 'Đã gửi yêu cầu đặt slot đến thủ thư', result, 201);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

exports.getMine = async (req, res, next) => {
    try {
        if (!req.user.readerId) return sendError(res, 'Tài khoản chưa liên kết hồ sơ độc giả!', 403);
        const result = await service.getMyReservations({ reader_id: req.user.readerId });
        return sendSuccess(res, 'Lấy danh sách đặt slot thành công', result);
    } catch (error) {
        next(error);
    }
};

exports.getAll = async (req, res, next) => {
    try {
        const result = await service.getAllReservations({
            status: req.query.status || 'active',
            keyword: req.query.keyword || '',
            reader_id: req.query.reader_id || '',
            page: parseInt(req.query.page || 1, 10),
            limit: parseInt(req.query.limit || 20, 10)
        });
        return sendSuccess(res, 'Lấy danh sách yêu cầu đặt slot thành công', result);
    } catch (error) {
        next(error);
    }
};

exports.approve = async (req, res) => {
    try {
        const result = await service.approveReservation({
            reservation_id: req.params.id,
            pickup_expires_at: req.body.pickup_expires_at,
            processed_by: req.user.userId
        });
        return sendSuccess(res, 'Đã duyệt và giữ bản sách cho độc giả', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

exports.reject = async (req, res) => {
    try {
        const result = await service.rejectReservation({
            reservation_id: req.params.id,
            reason: req.body.reason || '',
            processed_by: req.user.userId
        });
        return sendSuccess(res, 'Đã từ chối yêu cầu đặt slot', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

exports.cancel = async (req, res) => {
    try {
        const result = await service.cancelReservation({
            reservation_id: req.params.id,
            reader_id: req.user.readerId,
            user_role: req.user.role
        });
        return sendSuccess(res, 'Đã hủy yêu cầu đặt slot', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

