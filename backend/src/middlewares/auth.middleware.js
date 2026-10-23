const jwt = require('jsonwebtoken');
const db = require('../config/db');
const { getJwtSecret, hashToken, passwordVersion } = require('../config/security');
const { sendError } = require('../utils/response');

const JWT_SECRET = getJwtSecret();

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
        decoded = jwt.verify(token, JWT_SECRET);
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return sendError(res, 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại!', 401);
        }
        return sendError(res, 'Mã xác thực không hợp lệ!', 401);
    }

    try {
        // Kiểm tra xem token có nằm trong blacklist không (đã đăng xuất)
        const [blacklisted] = await db.query(
            'SELECT id FROM token_blacklist WHERE token IN (?, ?) LIMIT 1',
            [hashToken(token), token]
        );
        if (blacklisted.length > 0) {
            return sendError(res, 'Phiên đăng nhập đã kết thúc do bạn đã đăng xuất! Vui lòng đăng nhập lại.', 401);
        }

        const [users] = await db.query(
            `SELECT u.user_id, u.username, u.password_hash, u.role, u.is_active,
                    r.reader_id, r.reader_code
             FROM users u
             LEFT JOIN readers r ON r.user_id = u.user_id
             WHERE u.user_id = ?
             LIMIT 1`,
            [decoded.userId]
        );
        if (users.length === 0 || !Number(users[0].is_active)) {
            return sendError(res, 'Tài khoản không tồn tại hoặc đã bị khóa!', 401);
        }

        const currentUser = users[0];
        if (!decoded.passwordVersion ||
            decoded.passwordVersion !== passwordVersion(currentUser.password_hash)) {
            return sendError(res, 'Phiên đăng nhập không còn hiệu lực, vui lòng đăng nhập lại!', 401);
        }

        req.user = {
            ...decoded,
            userId: currentUser.user_id,
            username: currentUser.username,
            role: currentUser.role,
            readerId: currentUser.role === 'reader' ? currentUser.reader_id : null,
            readerCode: currentUser.role === 'reader' ? currentUser.reader_code : null
        };
        req.token = token;
        return next();
    } catch (error) {
        console.error('[Auth Middleware] Không thể kiểm tra token blacklist:', error.message);
        return sendError(res, 'Không thể kiểm tra phiên đăng nhập do lỗi cơ sở dữ liệu!', 500);
    }
};
