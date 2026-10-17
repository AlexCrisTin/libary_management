const express = require('express');
const controller = require('./pickupReservations.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');

const router = express.Router();
router.use(authMiddleware);

router.get('/my-reservations', roleMiddleware('reader'), controller.getMine);
router.post('/', roleMiddleware('reader'), controller.create);
router.get('/', roleMiddleware('librarian', 'admin'), controller.getAll);
router.put('/:id/approve', roleMiddleware('librarian', 'admin'), controller.approve);
router.put('/:id/reject', roleMiddleware('librarian', 'admin'), controller.reject);
router.put('/:id/cancel', controller.cancel);

module.exports = router;

