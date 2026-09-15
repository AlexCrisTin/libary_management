const { sendError } = require('../utils/response');

module.exports = (...allowedRoles) => {
    return (req, res, next) => {
        if (!req.user || !allowedRoles.includes(req.user.role)) {
            return sendError(res, 'Bạn không có quyền thực hiện hành động này!', 403);
        }
        next();
    };
};
