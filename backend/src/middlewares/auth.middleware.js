const jwt = require('jsonwebtoken');
const { sendError } = require('../utils/response');

module.exports = (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return sendError(res, 'Vui lòng đăng nhập để thực hiện chức năng này!', 401);
        }

        const token = authHeader.split(' ')[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'super_secret_library_jwt_key_2024');
        req.user = decoded;
        next();
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return sendError(res, 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại!', 401);
        }
        return sendError(res, 'Mã xác thực không hợp lệ!', 401);
    }
};
