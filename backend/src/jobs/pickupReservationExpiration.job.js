const { expireReservations } = require('../modules/pickupReservations/pickupReservations.service');

let schedulerTimer = null;

function startPickupReservationScheduler(intervalMinutes = 15) {
    const run = async () => {
        try {
            const result = await expireReservations();
            if (result.expired > 0) {
                console.log(`[Pickup Scheduler] Đã giải phóng ${result.expired} slot nhận sách hết hạn.`);
            }
        } catch (error) {
            console.error('[Pickup Scheduler] Lỗi khi xử lý slot nhận sách:', error.message);
        }
    };
    setTimeout(run, 5000);
    schedulerTimer = setInterval(run, intervalMinutes * 60 * 1000);
}

function stopPickupReservationScheduler() {
    if (schedulerTimer) clearInterval(schedulerTimer);
    schedulerTimer = null;
}

module.exports = { startPickupReservationScheduler, stopPickupReservationScheduler };
