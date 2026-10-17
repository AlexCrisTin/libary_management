require('dotenv').config();
const app = require('./src/app');
const { startOverdueScheduler, stopOverdueScheduler } = require('./src/jobs/overdueNotification.job');
const { startCardExpirationScheduler, stopCardExpirationScheduler } = require('./src/jobs/cardExpirationNotification.job');
const { startPickupReservationScheduler, stopPickupReservationScheduler } = require('./src/jobs/pickupReservationExpiration.job');
const { startHoldExpirationScheduler, stopHoldExpirationScheduler } = require('./src/jobs/holdExpiration.job');

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';
const AUTOMATIONS_ENABLED = process.env.AUTOMATIONS_ENABLED !== 'false';

const positiveMinutes = (name, fallback) => {
    const value = Number(process.env[name] || fallback);
    if (!Number.isFinite(value) || value <= 0) {
        console.warn(`[Server] ${name} không hợp lệ, dùng mặc định ${fallback} phút.`);
        return fallback;
    }
    return value;
};

const server = app.listen(PORT, HOST, () => {
    console.log(`[Server] Server đang chạy tại: http://${HOST}:${PORT}`);
    console.log(`[Books API] Sẵn sàng tại: http://${HOST}:${PORT}/api/books`);

    if (AUTOMATIONS_ENABLED) {
        startOverdueScheduler(positiveMinutes('OVERDUE_SCAN_INTERVAL_MINUTES', 60));
        startCardExpirationScheduler(positiveMinutes('CARD_SCAN_INTERVAL_MINUTES', 60));
        startPickupReservationScheduler(positiveMinutes('PICKUP_SCAN_INTERVAL_MINUTES', 15));
        startHoldExpirationScheduler(positiveMinutes('HOLD_SCAN_INTERVAL_MINUTES', 15));
    } else {
        console.log('[Server] Các tác vụ tự động đang được tắt bằng cấu hình môi trường.');
    }
});

let shuttingDown = false;
const shutdown = (signal) => {
    if (shuttingDown) return;
    shuttingDown = true;
    console.log(`[Server] Nhận ${signal}, đang dừng tác vụ tự động và đóng máy chủ...`);
    stopOverdueScheduler();
    stopCardExpirationScheduler();
    stopPickupReservationScheduler();
    stopHoldExpirationScheduler();
    server.close(() => {
        console.log('[Server] Đã dừng an toàn.');
        process.exit(0);
    });
    setTimeout(() => process.exit(1), 10000).unref();
};

process.once('SIGINT', () => shutdown('SIGINT'));
process.once('SIGTERM', () => shutdown('SIGTERM'));
