const { sendError } = require('../utils/response');

module.exports = (...allowedRoles) => {
    return (req, res, next) => {
        if (!req.user || !allowedRoles.includes(req.user.role)) {
            return sendError(res, 'Ban khong co quyen thuc hien hanh dong nay!', 403);
        }
        next();
    };
};
