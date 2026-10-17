const { expireReservations } = require('../modules/pickupReservations/pickupReservations.service');
const { createJobScheduler } = require('./jobScheduler');

const pickupReservationScheduler = createJobScheduler({
    name: 'Pickup Scheduler',
    task: expireReservations,
    initialDelayMs: 5000,
    onSuccess: (result) => {
        if (result.expired > 0) {
            console.log(`[Pickup Scheduler] Đã giải phóng ${result.expired} slot nhận sách hết hạn.`);
        }
    }
});

function startPickupReservationScheduler(intervalMinutes = 15) {
    return pickupReservationScheduler.start(intervalMinutes);
}

function stopPickupReservationScheduler() {
    return pickupReservationScheduler.stop();
}

module.exports = {
    startPickupReservationScheduler,
    stopPickupReservationScheduler,
    getPickupReservationSchedulerStatus: pickupReservationScheduler.getStatus
};
