const express = require('express');
const dashboardController = require('./dashboard.controller');

const router = express.Router();

router.get('/statistics', dashboardController.getStatistics);

module.exports = router;
