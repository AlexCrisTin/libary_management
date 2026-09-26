const categoriesService = require('./categories.service');
const { sendSuccess, sendError } = require('../../utils/response');

/**
 * 1. GET /api/categories - Lấy danh sách thể loại sách (Công khai)
 */
exports.getAllCategories = async (req, res, next) => {
    try {
        const { keyword, page, limit } = req.query;
        const result = await categoriesService.getAllCategories({
            keyword,
            page: parseInt(page || 1, 10),
            limit: parseInt(limit || 50, 10)
        });
        return sendSuccess(res, 'Lấy danh sách thể loại thành công', result);
    } catch (error) {
        next(error);
    }
};

/**
 * 2. GET /api/categories/:id - Xem chi tiết một thể loại
 */
exports.getCategoryById = async (req, res, next) => {
    try {
        const { id } = req.params;
        const category = await categoriesService.getCategoryById(id);
        if (!category) {
            return sendError(res, 'Không tìm thấy thể loại sách này!', 404);
        }
        return sendSuccess(res, 'Lấy chi tiết thể loại thành công', category);
    } catch (error) {
        next(error);
    }
};

/**
 * 3. POST /api/categories - Thêm thể loại mới (Thủ thư/Admin)
 */
exports.createCategory = async (req, res, next) => {
    try {
        const { category_name, ddc_code, description } = req.body;
        const result = await categoriesService.createCategory({
            category_name,
            ddc_code,
            description
        });
        return sendSuccess(res, 'Tạo thể loại sách thành công', result, 201);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 4. PUT /api/categories/:id - Chỉnh sửa thể loại (Thủ thư/Admin)
 */
exports.updateCategory = async (req, res, next) => {
    try {
        const { id } = req.params;
        const result = await categoriesService.updateCategory(id, req.body);
        return sendSuccess(res, 'Cập nhật thể loại sách thành công', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 5. DELETE /api/categories/:id - Xóa thể loại (Thủ thư/Admin)
 */
exports.deleteCategory = async (req, res, next) => {
    try {
        const { id } = req.params;
        const result = await categoriesService.deleteCategory(id);
        return sendSuccess(res, 'Xóa thể loại sách thành công', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};
