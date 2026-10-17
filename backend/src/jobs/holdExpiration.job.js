const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');
const { createJobScheduler } = require('./jobScheduler');

async function reorderWaitingQueue(conn, bibId) {
    const [waiting] = await conn.query(
        `SELECT hold_id FROM holds
         WHERE bib_id = ? AND status = 'waiting'
           AND (expires_at IS NULL OR expires_at > NOW())
         ORDER BY requested_at ASC, hold_id ASC`,
        [bibId]
    );
    for (let index = 0; index < waiting.length; index++) {
        await conn.query(
            'UPDATE holds SET queue_position = ? WHERE hold_id = ?',
            [index + 1, waiting[index].hold_id]
        );
    }
}

/**
 * Hủy đăng ký chờ sau 14 ngày và giải phóng lượt giữ tại quầy sau 3 ngày.
 */
async function scanAndExpireHolds() {
    const conn = await db.getConnection();
    const summary = { waiting_expired: 0, pickup_expired: 0, promoted: 0 };
    try {
        await conn.beginTransaction();

        const [expiredWaiting] = await conn.query(
            `SELECT hold_id, reader_id, bib_id
             FROM holds
             WHERE status = 'waiting' AND expires_at IS NOT NULL AND expires_at <= NOW()
             FOR UPDATE`
        );
        const affectedBooks = new Set();
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
                    'Đăng ký chờ sách đã hết hiệu lực',
                    'Sau 14 ngày, sách vẫn chưa có bản sẵn sàng. Bạn có thể đăng ký lại nếu vẫn còn nhu cầu.',
                    hold.hold_id
                ]
            );
            affectedBooks.add(hold.bib_id);
            summary.waiting_expired++;
        }
        for (const bibId of affectedBooks) {
            await reorderWaitingQueue(conn, bibId);
        }

        const [expiredPickups] = await conn.query(
            `SELECT h.*, br.title AS book_title
             FROM holds h
             JOIN bibliographic_records br ON br.bib_id = h.bib_id
             WHERE h.status = 'notified' AND h.expires_at IS NOT NULL
               AND h.expires_at <= NOW()
             FOR UPDATE`
        );
        for (const hold of expiredPickups) {
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
                    'Đã hết thời gian nhận sách',
                    `Thời gian nhận sách "${hold.book_title}" đã kết thúc. Bản sách sẽ được chuyển cho người tiếp theo.`,
                    hold.hold_id
                ]
            );

            const [nextRows] = await conn.query(
                `SELECT hold_id, reader_id, queue_position
                 FROM holds
                 WHERE bib_id = ? AND status = 'waiting'
                   AND (expires_at IS NULL OR expires_at > NOW())
                 ORDER BY queue_position ASC, requested_at ASC
                 LIMIT 1 FOR UPDATE`,
                [hold.bib_id]
            );
            if (nextRows.length > 0) {
                const next = nextRows[0];
                await conn.query(
                    `UPDATE holds
                     SET status = 'notified', notified_at = NOW(),
                         expires_at = DATE_ADD(NOW(), INTERVAL 3 DAY), queue_position = NULL
                     WHERE hold_id = ?`,
                    [next.hold_id]
                );
                await conn.query(
                    `INSERT INTO notifications
                     (notification_id, reader_id, title, content, type, reference_id, is_read, created_at)
                     VALUES (?, ?, ?, ?, 'hold_available', ?, 0, NOW())`,
                    [
                        uuidv4(),
                        next.reader_id,
                        'Sách bạn đăng ký đã có sẵn',
                        `Sách "${hold.book_title}" đã được giữ tại quầy. Vui lòng đến nhận trong vòng 3 ngày.`,
                        next.hold_id
                    ]
                );
                await reorderWaitingQueue(conn, hold.bib_id);
                summary.promoted++;
            } else {
                await conn.query(
                    `UPDATE book_copies bc SET status = 'available'
                     WHERE bc.bib_id = ? AND bc.status = 'reserved'
                       AND NOT EXISTS (
                           SELECT 1 FROM pickup_reservations pr
                           WHERE pr.copy_id = bc.copy_id AND pr.status = 'approved'
                       )
                     LIMIT 1`,
                    [hold.bib_id]
                );
            }
            summary.pickup_expired++;
        }

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
        if (result.waiting_expired || result.pickup_expired || result.promoted) {
            console.log(
                `[Hold Scheduler] Hết hạn chờ: ${result.waiting_expired}, ` +
                `hết hạn nhận: ${result.pickup_expired}, chuyển lượt: ${result.promoted}.`
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
