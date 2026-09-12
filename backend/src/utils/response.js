/**
 * Chuẩn hóa định dạng phản hồi JSON cho Frontend Flutter
 */
const sendSuccess = (res, message = 'Thành công', data = null, statusCode = 200) => {
    return res.status(statusCode).json({
        success: true,
        message,
        data
    });
};

const sendError = (res, message = 'Đã có lỗi xảy ra', statusCode = 400, errors = null) => {
    const payload = {
        success: false,
        message
    };
    if (errors) {
        payload.errors = errors;
    }
    return res.status(statusCode).json(payload);
};

module.exports = {
    sendSuccess,
    sendError
};
