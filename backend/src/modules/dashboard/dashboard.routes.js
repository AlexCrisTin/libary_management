const express = require('express');
const dashboardController = require('./dashboard.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');

const router = express.Router();

// Thống kê Dashboard chỉ dành riêng cho Thủ thư và Admin
router.use(authMiddleware);
router.use(roleMiddleware('librarian', 'admin'));

router.get('/statistics', dashboardController.getStatistics);

module.exports = router;
