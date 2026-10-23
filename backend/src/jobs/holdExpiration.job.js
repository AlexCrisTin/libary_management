const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');
const { createJobScheduler } = require('./jobScheduler');

/**
 * Hủy đăng ký báo khi có sau 14 ngày và đóng cửa sổ đặt slot sau khi đã báo.
 * Hold không được phép giữ bản sao; chỉ pickup reservation đã duyệt mới làm vậy.
 */
async function scanAndExpireHolds() {
    const conn = await db.getConnection();
    const summary = {
        waiting_expired: 0,
        notification_expired: 0,
        orphan_copies_released: 0
    };
    try {
        await conn.beginTransaction();

        const [expiredWaiting] = await conn.query(
            `SELECT hold_id, reader_id, bib_id
             FROM holds
             WHERE status = 'waiting' AND expires_at IS NOT NULL AND expires_at <= NOW()
             FOR UPDATE`
        );
        for (const hold of expiredWaiting) {
            await conn.query(
                `UPDATE holds SET status = 'expired', queue_position = NULL
                 WHERE hold_id = ?`,
                [hold.hold_id]
            );
            await conn.query(
                `INSERT INTO notifications
                 (notification_id, reader_id, title, content, type, reference_id, is_read, created_at)
                 VALUES (?, ?, ?, ?, 'system', ?, 0, NOW())`,
                [
                    uuidv4(),
                    hold.reader_id,
                    'Đăng ký báo khi có đã hết hiệu lực',
                    'Sau 14 ngày, sách vẫn chưa có bản sẵn sàng. Bạn có thể bật báo khi có lại nếu vẫn còn nhu cầu.',
                    hold.hold_id
                ]
            );
            summary.waiting_expired++;
        }

        const [expiredNotifications] = await conn.query(
            `SELECT h.*, br.title AS book_title
             FROM holds h
             JOIN bibliographic_records br ON br.bib_id = h.bib_id
             WHERE h.status = 'notified' AND h.expires_at IS NOT NULL
               AND h.expires_at <= NOW()
             FOR UPDATE`
        );
        for (const hold of expiredNotifications) {
            await conn.query(
                `UPDATE holds SET status = 'expired', queue_position = NULL
                 WHERE hold_id = ?`,
                [hold.hold_id]
            );
            await conn.query(
                `INSERT INTO notifications
                 (notification_id, reader_id, title, content, type, reference_id, is_read, created_at)
                 VALUES (?, ?, ?, ?, 'system', ?, 0, NOW())`,
                [
                    uuidv4(),
                    hold.reader_id,
                    'Thông báo sách có lại đã hết hiệu lực',
                    `Thông báo cho sách "${hold.book_title}" đã hết hiệu lực. Hãy mở chi tiết sách để kiểm tra lại tình trạng hiện tại.`,
                    hold.hold_id
                ]
            );
            summary.notification_expired++;
        }

        // Dọn dữ liệu cũ từng giữ sách bằng hold. Bản sao reserved hợp lệ phải
        // luôn gắn với một pickup reservation đã được thủ thư duyệt.
        const [released] = await conn.query(
            `UPDATE book_copies bc
             SET bc.status = 'available'
             WHERE bc.status = 'reserved'
               AND NOT EXISTS (
                   SELECT 1 FROM pickup_reservations pr
                   WHERE pr.copy_id = bc.copy_id AND pr.status = 'approved'
               )`
        );
        summary.orphan_copies_released = Number(released.affectedRows || 0);

        await conn.commit();
        return summary;
    } catch (error) {
        await conn.rollback();
        throw error;
    } finally {
        conn.release();
    }
}

const holdExpirationScheduler = createJobScheduler({
    name: 'Hold Scheduler',
    task: scanAndExpireHolds,
    initialDelayMs: 6000,
    onSuccess: (result) => {
        if (
            result.waiting_expired ||
            result.notification_expired ||
            result.orphan_copies_released
        ) {
            console.log(
                `[Hold Scheduler] Hết hạn đăng ký: ${result.waiting_expired}, ` +
                `hết hạn thông báo: ${result.notification_expired}, ` +
                `bản sao giữ sai đã mở lại: ${result.orphan_copies_released}.`
            );
        }
    }
});

function startHoldExpirationScheduler(intervalMinutes = 15) {
    return holdExpirationScheduler.start(intervalMinutes);
}

function stopHoldExpirationScheduler() {
    return holdExpirationScheduler.stop();
}

module.exports = {
    scanAndExpireHolds,
    startHoldExpirationScheduler,
    stopHoldExpirationScheduler,
    getHoldExpirationSchedulerStatus: holdExpirationScheduler.getStatus
};
