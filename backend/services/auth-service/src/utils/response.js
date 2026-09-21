/**
 * Tra ve response thanh cong chuan
 */
exports.sendSuccess = (res, message = 'Thanh cong', data = null, statusCode = 200) => {
    return res.status(statusCode).json({
        success: true,
        message,
        data
    });
};

/**
 * Tra ve response loi chuan
 */
exports.sendError = (res, message = 'Da xay ra loi', statusCode = 500, errors = null) => {
    const response = {
        success: false,
        message
    };
    if (errors) {
        response.errors = errors;
    }
    return res.status(statusCode).json(response);
};
