const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');

async function scanAndNotifyCardExpiration() {
    const summary = { scanned: 0, notified: 0, expired_updated: 0 };
    const [readers] = await db.query(
        `SELECT reader_id, full_name, card_expired, status,
                DATEDIFF(card_expired, CURDATE()) AS days_left
         FROM readers
         WHERE card_expired IS NOT NULL
           AND card_expired <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)
           AND status <> 'suspended'`
    );
    summary.scanned = readers.length;

    for (const reader of readers) {
        const expired = Number(reader.days_left) < 0;
        if (expired && reader.status !== 'expired') {
            await db.query('UPDATE readers SET status = "expired" WHERE reader_id = ?', [reader.reader_id]);
            summary.expired_updated++;
        }

        const title = expired ? 'Thẻ thư viện đã hết hạn' : 'Thẻ thư viện sắp hết hạn';
        const [existing] = await db.query(
            `SELECT notification_id FROM notifications
             WHERE reader_id = ? AND type = 'card_expired' AND title = ?
             LIMIT 1`,
            [reader.reader_id, title]
        );
        if (existing.length > 0) continue;

        const formattedDate = new Date(reader.card_expired).toLocaleDateString('vi-VN');
        const content = expired
            ? `Thẻ thư viện của bạn đã hết hạn ngày ${formattedDate}. Vui lòng liên hệ thủ thư để gia hạn trước khi tiếp tục mượn hoặc đặt trước sách.`
            : `Thẻ thư viện của bạn sẽ hết hạn ngày ${formattedDate} (còn ${reader.days_left} ngày). Vui lòng liên hệ thủ thư để được gia hạn.`;

        await db.query(
            `INSERT INTO notifications
             (notification_id, reader_id, title, content, type, reference_id, is_read, created_at)
             VALUES (?, ?, ?, ?, 'card_expired', ?, 0, NOW())`,
            [uuidv4(), reader.reader_id, title, content, reader.reader_id]
        );
        summary.notified++;
    }
    return summary;
}

let schedulerTimer = null;

function startCardExpirationScheduler(intervalMinutes = 60) {
    const run = async () => {
        try {
            const result = await scanAndNotifyCardExpiration();
            console.log(`[Card Scheduler] Đã quét ${result.scanned} thẻ, tạo ${result.notified} thông báo, cập nhật ${result.expired_updated} thẻ hết hạn.`);
        } catch (error) {
            console.error('[Card Scheduler] Lỗi khi quét hạn thẻ:', error.message);
        }
    };
    setTimeout(run, 4000);
    schedulerTimer = setInterval(run, intervalMinutes * 60 * 1000);
}

function stopCardExpirationScheduler() {
    if (schedulerTimer) clearInterval(schedulerTimer);
    schedulerTimer = null;
}

module.exports = {
    scanAndNotifyCardExpiration,
    startCardExpirationScheduler,
    stopCardExpirationScheduler
};
