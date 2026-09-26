const express = require('express');
const router = express.Router();
const uploadsController = require('./uploads.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');

router.post(
    '/book-cover',
    authMiddleware,
    roleMiddleware('librarian', 'admin'),
    uploadsController.uploadBookCover
);

module.exports = router;
