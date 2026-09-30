const jwt = require('jsonwebtoken');
const db = require('../config/db');
const { sendError } = require('../utils/response');

module.exports = async (req, res, next) => {
    let token;
    let decoded;

    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return sendError(res, 'Vui lòng đăng nhập để thực hiện chức năng này!', 401);
        }

        token = authHeader.slice(7).trim();
        if (!token) {
            return sendError(res, 'Vui lòng đăng nhập để thực hiện chức năng này!', 401);
        }
        decoded = jwt.verify(token, process.env.JWT_SECRET || 'super_secret_library_jwt_key_2024');
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return sendError(res, 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại!', 401);
        }
        return sendError(res, 'Mã xác thực không hợp lệ!', 401);
    }

    try {
        // Kiểm tra xem token có nằm trong blacklist không (đã đăng xuất)
        const [blacklisted] = await db.query(
            'SELECT id FROM token_blacklist WHERE token = ? LIMIT 1',
            [token]
        );
        if (blacklisted.length > 0) {
            return sendError(res, 'Phiên đăng nhập đã kết thúc do bạn đã đăng xuất! Vui lòng đăng nhập lại.', 401);
        }

        req.user = decoded;
        req.token = token;
        return next();
    } catch (error) {
        console.error('[Auth Middleware] Không thể kiểm tra token blacklist:', error.message);
        return sendError(res, 'Không thể kiểm tra phiên đăng nhập do lỗi cơ sở dữ liệu!', 500);
    }
};
