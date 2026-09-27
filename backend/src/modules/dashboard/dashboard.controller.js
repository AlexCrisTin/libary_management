const dashboardService = require('./dashboard.service');
const { sendSuccess, sendError } = require('../../utils/response');

exports.getStatistics = async (req, res, next) => {
    try {
        const days = Number(req.query.days || 7);
        if (!Number.isInteger(days) || ![7, 30, 90].includes(days)) {
            return sendError(res, 'Khoảng thống kê chỉ hỗ trợ 7, 30 hoặc 90 ngày.', 400);
        }

        const statistics = await dashboardService.getStatistics({ days });
        return sendSuccess(res, 'Lấy thống kê dashboard thành công', statistics);
    } catch (error) {
        next(error);
    }
};
