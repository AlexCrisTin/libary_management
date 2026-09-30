const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');

/**
 * Ham quet va tu dong tao thong bao cho sach qua han va sap den han
 */
async function scanAndNotifyOverdue() {
    const summary = {
        scanned_overdue: 0,
        overdue_updated: 0,
        overdue_notified: 0,
        scanned_due_soon: 0,
        due_soon_notified: 0
    };

    // 1. Quet cac sach DA QUA HAN (due_date < CURDATE() va status IN ('borrowed', 'overdue'))
    const overdueSql = `
        SELECT 
            bt.tx_id,
            bt.reader_id,
            bt.copy_id,
            bt.borrow_date,
            bt.due_date,
            bt.status,
            DATEDIFF(CURDATE(), bt.due_date) AS days_overdue,
            bc.barcode,
            br.title AS book_title,
            r.full_name AS reader_name
        FROM borrow_transactions bt
        JOIN book_copies bc ON bt.copy_id = bc.copy_id
        JOIN bibliographic_records br ON bc.bib_id = br.bib_id
        JOIN readers r ON bt.reader_id = r.reader_id
        WHERE bt.due_date < CURDATE()
          AND bt.status IN ('borrowed', 'overdue')
          AND bt.return_date IS NULL
    `;

    const [overdueLoans] = await db.query(overdueSql);
    summary.scanned_overdue = overdueLoans.length;

    for (const loan of overdueLoans) {
        // Neu giao dich dang co trang thai 'borrowed' thi tu dong cap nhat sang 'overdue'
        if (loan.status === 'borrowed') {
            await db.query('UPDATE borrow_transactions SET status = "overdue" WHERE tx_id = ?', [loan.tx_id]);
            summary.overdue_updated++;
        }

        // Tinh tien phat du kien (2.000 VND / ngay tre han)
        const fineEst = Math.max(0, loan.days_overdue) * 2000;
        const formattedFine = new Intl.NumberFormat('vi-VN').format(fineEst);
        const formattedDueDate = new Date(loan.due_date).toLocaleDateString('vi-VN');

        // Kiem tra xem hom nay da gui thong bao qua han cho giao dich (tx_id) nay chua
        const checkSql = `
            SELECT notification_id FROM notifications 
            WHERE reference_id = ? 
              AND type = 'overdue' 
              AND DATE(created_at) = CURDATE()
            LIMIT 1
        `;
        const [existingNotifs] = await db.query(checkSql, [loan.tx_id]);

        if (existingNotifs.length === 0) {
            const notifId = uuidv4();
            const title = `Cảnh báo: Sách quá hạn trả - ${loan.book_title}`;
            const content = `Sách "${loan.book_title}" (Mã vạch: ${loan.barcode}) của bạn đã quá hạn ${loan.days_overdue} ngày (Hạn trả: ${formattedDueDate}). Tiền phạt trễ hạn tạm tính: ${formattedFine} VNĐ. Vui lòng đến thư viện trả sách hoặc liên hệ thủ thư để được hỗ trợ.`;

            await db.query(
                `INSERT INTO notifications (notification_id, reader_id, title, content, type, reference_id, is_read, created_at)
                 VALUES (?, ?, ?, ?, 'overdue', ?, 0, NOW())`,
                [notifId, loan.reader_id, title, content, loan.tx_id]
            );
            summary.overdue_notified++;
        }
    }

    // 2. Quet cac sach SAP DEN HAN TRA (trong vong 2 ngay toi)
    const dueSoonSql = `
        SELECT 
            bt.tx_id,
            bt.reader_id,
            bt.due_date,
            DATEDIFF(bt.due_date, CURDATE()) AS days_left,
            bc.barcode,
            br.title AS book_title,
            r.full_name AS reader_name
        FROM borrow_transactions bt
        JOIN book_copies bc ON bt.copy_id = bc.copy_id
        JOIN bibliographic_records br ON bc.bib_id = br.bib_id
        JOIN readers r ON bt.reader_id = r.reader_id
        WHERE bt.due_date >= CURDATE()
          AND bt.due_date <= DATE_ADD(CURDATE(), INTERVAL 2 DAY)
          AND bt.status = 'borrowed'
          AND bt.return_date IS NULL
    `;

    const [dueSoonLoans] = await db.query(dueSoonSql);
    summary.scanned_due_soon = dueSoonLoans.length;

    for (const loan of dueSoonLoans) {
        // Kiem tra xem da gui thong bao due_soon cho giao dich nay trong 2 ngay qua chua
        const checkSql = `
            SELECT notification_id FROM notifications 
            WHERE reference_id = ? 
              AND type = 'due_soon' 
              AND created_at >= DATE_SUB(NOW(), INTERVAL 2 DAY)
            LIMIT 1
        `;
        const [existingNotifs] = await db.query(checkSql, [loan.tx_id]);

        if (existingNotifs.length === 0) {
            const notifId = uuidv4();
            const daysText = loan.days_left === 0 ? 'hôm nay' : `còn ${loan.days_left} ngày nữa`;
            const formattedDueDate = new Date(loan.due_date).toLocaleDateString('vi-VN');
            const title = `Nhắc nhở: Sách sắp đến hạn trả - ${loan.book_title}`;
            const content = `Sách "${loan.book_title}" (Mã vạch: ${loan.barcode}) của bạn sẽ đến hạn trả vào ngày ${formattedDueDate} (${daysText}). Vui lòng sắp xếp trả sách đúng hạn hoặc gia hạn trên ứng dụng để tránh phát sinh phí quá hạn.`;

            await db.query(
                `INSERT INTO notifications (notification_id, reader_id, title, content, type, reference_id, is_read, created_at)
                 VALUES (?, ?, ?, ?, 'due_soon', ?, 0, NOW())`,
                [notifId, loan.reader_id, title, content, loan.tx_id]
            );
            summary.due_soon_notified++;
        }
    }

    return summary;
}

let schedulerTimer = null;

/**
 * Khoi dong bo hen gio quet tu dong dinh ky chay ngam
 * @param {number} intervalMinutes So phut giua cac lan quet (Mac dinh: 60 phut)
 */
function startOverdueScheduler(intervalMinutes = 60) {
    console.log(`[Scheduler] Khởi động tiến trình tự động quét sách quá hạn (Định kỳ: ${intervalMinutes} phút/lần)...`);

    // Quet ngay 1 lan sau khi server khoi dong 3 giay
    setTimeout(async () => {
        try {
            console.log('[Scheduler] Bắt đầu quét kiểm tra sách quá hạn & sắp đến hạn...');
            const result = await scanAndNotifyOverdue();
            console.log(`[Scheduler] Hoàn tất quét khởi động: Đã quét ${result.scanned_overdue} sách quá hạn (${result.overdue_updated} cập nhật status, ${result.overdue_notified} thông báo mới), ${result.scanned_due_soon} sách sắp hết hạn (${result.due_soon_notified} thông báo mới).`);
        } catch (err) {
            console.error('[Scheduler] Lỗi khi quét sách quá hạn lúc khởi động:', err.message);
        }
    }, 3000);

    // Thiet lap chu ky dinh ky
    schedulerTimer = setInterval(async () => {
        try {
            console.log('[Scheduler] Đang thực hiện quét sách quá hạn định kỳ...');
            const result = await scanAndNotifyOverdue();
            console.log(`[Scheduler] Hoàn tất quét định kỳ: ${result.overdue_notified} thông báo quá hạn mới, ${result.due_soon_notified} thông báo sắp hết hạn mới.`);
        } catch (err) {
            console.error('[Scheduler] Lỗi khi thực hiện quét định kỳ:', err.message);
        }
    }, intervalMinutes * 60 * 1000);
}

function stopOverdueScheduler() {
    if (schedulerTimer) {
        clearInterval(schedulerTimer);
        schedulerTimer = null;
        console.log('[Scheduler] Đã dừng tiến trình quét tự động.');
    }
}

module.exports = {
    scanAndNotifyOverdue,
    startOverdueScheduler,
    stopOverdueScheduler
};
