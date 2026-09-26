const publishersService = require('./publishers.service');
const { sendSuccess, sendError } = require('../../utils/response');

/**
 * 1. GET /api/publishers - Xem danh sách nhà xuất bản (Công khai)
 */
exports.getAllPublishers = async (req, res, next) => {
    try {
        const { keyword, page, limit } = req.query;
        const result = await publishersService.getAllPublishers({
            keyword,
            page: parseInt(page || 1, 10),
            limit: parseInt(limit || 50, 10)
        });
        return sendSuccess(res, 'Lấy danh sách nhà xuất bản thành công', result);
    } catch (error) {
        next(error);
    }
};

/**
 * 2. GET /api/publishers/:id - Xem chi tiết một nhà xuất bản
 */
exports.getPublisherById = async (req, res, next) => {
    try {
        const { id } = req.params;
        const publisher = await publishersService.getPublisherById(id);
        if (!publisher) {
            return sendError(res, 'Không tìm thấy nhà xuất bản này!', 404);
        }
        return sendSuccess(res, 'Lấy chi tiết nhà xuất bản thành công', publisher);
    } catch (error) {
        next(error);
    }
};

/**
 * 3. POST /api/publishers - Thêm nhà xuất bản mới (Thủ thư/Admin)
 */
exports.createPublisher = async (req, res, next) => {
    try {
        const { name, address, contact_email } = req.body;
        const result = await publishersService.createPublisher({
            name,
            address,
            contact_email
        });
        return sendSuccess(res, 'Tạo nhà xuất bản thành công', result, 201);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 4. PUT /api/publishers/:id - Chỉnh sửa thông tin nhà xuất bản (Thủ thư/Admin)
 */
exports.updatePublisher = async (req, res, next) => {
    try {
        const { id } = req.params;
        const result = await publishersService.updatePublisher(id, req.body);
        return sendSuccess(res, 'Cập nhật nhà xuất bản thành công', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 5. DELETE /api/publishers/:id - Xóa nhà xuất bản (Thủ thư/Admin)
 */
exports.deletePublisher = async (req, res, next) => {
    try {
        const { id } = req.params;
        const result = await publishersService.deletePublisher(id);
        return sendSuccess(res, 'Xóa nhà xuất bản thành công', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};
