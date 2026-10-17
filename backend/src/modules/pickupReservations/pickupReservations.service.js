const db = require('../../config/db');
const { v4: uuidv4 } = require('uuid');

const ACTIVE_STATUSES = ['pending', 'approved'];
const MAX_PICKUP_WINDOW_MS = 7 * 24 * 60 * 60 * 1000;

const assertReaderCanReserve = (reader) => {
    if (!reader) throw new Error('Không tìm thấy hồ sơ độc giả!');
    if (reader.status !== 'active') {
        throw new Error(`Thẻ độc giả đang không hoạt động (Trạng thái: ${reader.status})!`);
    }
    if (!reader.card_expired) return;
    const expiredDate = new Date(reader.card_expired);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    if (expiredDate < today) {
        throw new Error('Thẻ thư viện đã hết hạn, không thể đặt slot nhận sách!');
    }
};

const normalizePickupExpiry = (value) => {
    const expiry = new Date(value);
    const now = new Date();
    if (Number.isNaN(expiry.getTime())) {
        throw new Error('Thời hạn đến lấy sách không hợp lệ!');
    }
    if (expiry.getTime() <= now.getTime()) {
        throw new Error('Thời hạn đến lấy sách phải ở trong tương lai!');
    }
    if (expiry.getTime() - now.getTime() > MAX_PICKUP_WINDOW_MS) {
        throw new Error('Thời hạn đến lấy sách không được vượt quá 7 ngày!');
    }
    return expiry;
};

/** Độc giả gửi yêu cầu giữ một đầu sách hiện đang còn bản sẵn có. */
exports.createReservation = async ({ reader_id, bib_id }) => {
    const [readers] = await db.query('SELECT * FROM readers WHERE reader_id = ?', [reader_id]);
    const reader = readers[0];
    assertReaderCanReserve(reader);

    const [books] = await db.query(
        'SELECT bib_id, title, isbn FROM bibliographic_records WHERE bib_id = ?',
        [bib_id]
    );
    if (books.length === 0) throw new Error('Không tìm thấy thông tin đầu sách này!');

    const [borrows] = await db.query(
        `SELECT bt.tx_id
         FROM borrow_transactions bt
         JOIN book_copies bc ON bc.copy_id = bt.copy_id
         WHERE bt.reader_id = ? AND bc.bib_id = ?
           AND bt.status IN ('borrowed', 'overdue')
         LIMIT 1`,
        [reader_id, bib_id]
    );
    if (borrows.length > 0) {
        throw new Error('Bạn đang mượn đầu sách này nên không thể đặt thêm slot!');
    }

    const [existing] = await db.query(
        `SELECT reservation_id, status
         FROM pickup_reservations
         WHERE reader_id = ? AND bib_id = ? AND status IN ('pending', 'approved')
         LIMIT 1`,
        [reader_id, bib_id]
    );
    if (existing.length > 0) {
        throw new Error('Bạn đã có một yêu cầu đặt slot đang được xử lý cho sách này!');
    }

    const [activeHolds] = await db.query(
        `SELECT hold_id FROM holds
         WHERE reader_id = ? AND bib_id = ? AND status IN ('waiting', 'notified')
         LIMIT 1`,
        [reader_id, bib_id]
    );
    if (activeHolds.length > 0) {
        throw new Error('Bạn đã có yêu cầu đặt trước đang hoạt động cho sách này!');
    }

    const [copies] = await db.query(
        `SELECT COUNT(*) AS available_copies
         FROM book_copies WHERE bib_id = ? AND status = 'available'`,
        [bib_id]
    );
    if (Number(copies[0].available_copies) < 1) {
        throw new Error('Sách hiện đã hết bản có sẵn. Hãy dùng chức năng đăng ký chờ sách!');
    }

    const reservationId = uuidv4();
    await db.query(
        `INSERT INTO pickup_reservations
         (reservation_id, reader_id, bib_id, status)
         VALUES (?, ?, ?, 'pending')`,
        [reservationId, reader_id, bib_id]
    );

    return {
        reservation_id: reservationId,
        reader_id,
        bib_id,
        book_title: books[0].title,
        status: 'pending',
        requested_at: new Date()
    };
};

/** Độc giả xem các yêu cầu của chính mình. */
exports.getMyReservations = async ({ reader_id }) => {
    await exports.expireReservations();
    const [rows] = await db.query(
        `SELECT pr.*, br.title AS book_title, br.isbn, br.cover_url,
                bc.barcode, sl.floor, sl.section, sl.shelf, sl.position
         FROM pickup_reservations pr
         JOIN bibliographic_records br ON br.bib_id = pr.bib_id
         LEFT JOIN book_copies bc ON bc.copy_id = pr.copy_id
         LEFT JOIN shelf_locations sl ON sl.location_id = bc.location_id
         WHERE pr.reader_id = ?
         ORDER BY pr.requested_at DESC`,
        [reader_id]
    );
    return rows;
};

/** Thủ thư xem và lọc danh sách yêu cầu đặt slot. */
exports.getAllReservations = async ({ status = 'active', keyword = '', page = 1, limit = 20 }) => {
    await exports.expireReservations();
    const normalizedPage = Math.max(1, Number(page) || 1);
    const normalizedLimit = Math.min(100, Math.max(1, Number(limit) || 20));
    const offset = (normalizedPage - 1) * normalizedLimit;
    const where = [];
    const params = [];

    if (status === 'active') {
        where.push("pr.status IN ('pending', 'approved')");
    } else if (status && status !== 'all') {
        where.push('pr.status = ?');
        params.push(status);
    }
    if (keyword.trim()) {
        where.push(`(r.full_name LIKE ? OR r.reader_code LIKE ? OR
                     br.title LIKE ? OR br.isbn LIKE ?)`);
        const pattern = `%${keyword.trim()}%`;
        params.push(pattern, pattern, pattern, pattern);
    }
    const whereClause = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const [countRows] = await db.query(
        `SELECT COUNT(*) AS total
         FROM pickup_reservations pr
         JOIN readers r ON r.reader_id = pr.reader_id
         JOIN bibliographic_records br ON br.bib_id = pr.bib_id
         ${whereClause}`,
        params
    );
    const total = Number(countRows[0].total);

    const [rows] = await db.query(
        `SELECT pr.*, r.full_name AS reader_name, r.reader_code,
                r.phone AS reader_phone, br.title AS book_title, br.isbn,
                bc.barcode, sl.floor, sl.section, sl.shelf, sl.position,
                u.full_name AS processed_by_name
         FROM pickup_reservations pr
         JOIN readers r ON r.reader_id = pr.reader_id
         JOIN bibliographic_records br ON br.bib_id = pr.bib_id
         LEFT JOIN book_copies bc ON bc.copy_id = pr.copy_id
         LEFT JOIN shelf_locations sl ON sl.location_id = bc.location_id
         LEFT JOIN users u ON u.user_id = pr.processed_by
         ${whereClause}
         ORDER BY FIELD(pr.status, 'pending', 'approved', 'expired', 'rejected', 'cancelled', 'fulfilled'),
                  pr.requested_at ASC
         LIMIT ? OFFSET ?`,
        [...params, normalizedLimit, offset]
    );

    return {
        total,
        page: normalizedPage,
        limit: normalizedLimit,
        total_pages: Math.max(1, Math.ceil(total / normalizedLimit)),
        data: rows
    };
};

/** Thủ thư duyệt yêu cầu, gán đúng một bản sao và đặt thời hạn đến lấy. */
exports.approveReservation = async ({ reservation_id, pickup_expires_at, processed_by }) => {
    const expiry = normalizePickupExpiry(pickup_expires_at);
    const conn = await db.getConnection();
    try {
        await conn.beginTransaction();
        const [rows] = await conn.query(
            `SELECT pr.*, br.title AS book_title
             FROM pickup_reservations pr
             JOIN bibliographic_records br ON br.bib_id = pr.bib_id
             WHERE pr.reservation_id = ? FOR UPDATE`,
            [reservation_id]
        );
        if (rows.length === 0) throw new Error('Không tìm thấy yêu cầu đặt slot!');
        const reservation = rows[0];
        if (reservation.status !== 'pending') {
            throw new Error('Chỉ có thể duyệt yêu cầu đang chờ xử lý!');
        }

        const [copies] = await conn.query(
            `SELECT copy_id, barcode
             FROM book_copies
             WHERE bib_id = ? AND status = 'available'
             ORDER BY acquired_date ASC, copy_id ASC
             LIMIT 1 FOR UPDATE`,
            [reservation.bib_id]
        );
        if (copies.length === 0) {
            throw new Error('Sách vừa hết bản có sẵn, chưa thể duyệt yêu cầu này!');
        }
        const copy = copies[0];
        await conn.query(
            `UPDATE book_copies SET status = 'reserved' WHERE copy_id = ?`,
            [copy.copy_id]
        );
        await conn.query(
            `UPDATE pickup_reservations
             SET copy_id = ?, status = 'approved', pickup_expires_at = ?,
                 processed_by = ?, processed_at = NOW(), rejection_reason = NULL
             WHERE reservation_id = ?`,
            [copy.copy_id, expiry, processed_by || null, reservation_id]
        );
        await conn.query(
            `INSERT INTO notifications
             (notification_id, reader_id, title, content, type, reference_id, is_read, created_at)
             VALUES (?, ?, ?, ?, 'system', ?, 0, NOW())`,
            [
                uuidv4(),
                reservation.reader_id,
                'Yêu cầu đặt slot đã được duyệt',
                `Sách "${reservation.book_title}" đã được giữ tại quầy đến ${expiry.toLocaleString('vi-VN')}. Vui lòng đến đúng hạn để nhận sách.`,
                reservation_id
            ]
        );
        await conn.commit();
        return {
            reservation_id,
            copy_id: copy.copy_id,
            barcode: copy.barcode,
            status: 'approved',
            pickup_expires_at: expiry
        };
    } catch (error) {
        await conn.rollback();
        throw error;
    } finally {
        conn.release();
    }
};

/** Thủ thư từ chối yêu cầu. */
exports.rejectReservation = async ({ reservation_id, reason = '', processed_by }) => {
    const conn = await db.getConnection();
    try {
        await conn.beginTransaction();
        const [rows] = await conn.query(
            `SELECT pr.*, br.title AS book_title
             FROM pickup_reservations pr
             JOIN bibliographic_records br ON br.bib_id = pr.bib_id
             WHERE pr.reservation_id = ? FOR UPDATE`,
            [reservation_id]
        );
        if (rows.length === 0) throw new Error('Không tìm thấy yêu cầu đặt slot!');
        const reservation = rows[0];
        if (reservation.status !== 'pending') {
            throw new Error('Chỉ có thể từ chối yêu cầu đang chờ xử lý!');
        }
        const rejectionReason = reason.trim() || 'Thư viện chưa thể giữ bản sách vào thời điểm này.';
        await conn.query(
            `UPDATE pickup_reservations
             SET status = 'rejected', processed_by = ?, processed_at = NOW(), rejection_reason = ?
             WHERE reservation_id = ?`,
            [processed_by || null, rejectionReason, reservation_id]
        );
        await conn.query(
            `INSERT INTO notifications
             (notification_id, reader_id, title, content, type, reference_id, is_read, created_at)
             VALUES (?, ?, ?, ?, 'system', ?, 0, NOW())`,
            [
                uuidv4(),
                reservation.reader_id,
                'Yêu cầu đặt slot chưa được duyệt',
                `Yêu cầu giữ sách "${reservation.book_title}" đã bị từ chối. Lý do: ${rejectionReason}`,
                reservation_id
            ]
        );
        await conn.commit();
        return { reservation_id, status: 'rejected', rejection_reason: rejectionReason };
    } catch (error) {
        await conn.rollback();
        throw error;
    } finally {
        conn.release();
    }
};

/** Độc giả hoặc thủ thư hủy yêu cầu chưa hoàn tất. */
exports.cancelReservation = async ({ reservation_id, reader_id, user_role }) => {
    const conn = await db.getConnection();
    try {
        await conn.beginTransaction();
        const [rows] = await conn.query(
            'SELECT * FROM pickup_reservations WHERE reservation_id = ? FOR UPDATE',
            [reservation_id]
        );
        if (rows.length === 0) throw new Error('Không tìm thấy yêu cầu đặt slot!');
        const reservation = rows[0];
        if (user_role === 'reader' && reservation.reader_id !== reader_id) {
            throw new Error('Bạn không có quyền hủy yêu cầu của độc giả khác!');
        }
        if (!ACTIVE_STATUSES.includes(reservation.status)) {
            throw new Error(`Không thể hủy yêu cầu ở trạng thái ${reservation.status}!`);
        }
        if (reservation.status === 'approved' && reservation.copy_id) {
            await conn.query(
                `UPDATE book_copies SET status = 'available'
                 WHERE copy_id = ? AND status = 'reserved'`,
                [reservation.copy_id]
            );
        }
        await conn.query(
            `UPDATE pickup_reservations SET status = 'cancelled' WHERE reservation_id = ?`,
            [reservation_id]
        );
        await conn.commit();
        return { reservation_id, status: 'cancelled' };
    } catch (error) {
        await conn.rollback();
        throw error;
    } finally {
        conn.release();
    }
};

/** Giải phóng các bản sao đã quá hạn đến lấy. */
exports.expireReservations = async () => {
    const conn = await db.getConnection();
    let expiredCount = 0;
    try {
        await conn.beginTransaction();
        const [rows] = await conn.query(
            `SELECT pr.*, br.title AS book_title
             FROM pickup_reservations pr
             JOIN bibliographic_records br ON br.bib_id = pr.bib_id
             WHERE pr.status = 'approved' AND pr.pickup_expires_at <= NOW()
             FOR UPDATE`
        );
        for (const reservation of rows) {
            if (reservation.copy_id) {
                await conn.query(
                    `UPDATE book_copies SET status = 'available'
                     WHERE copy_id = ? AND status = 'reserved'`,
                    [reservation.copy_id]
                );
            }
            await conn.query(
                `UPDATE pickup_reservations SET status = 'expired'
                 WHERE reservation_id = ?`,
                [reservation.reservation_id]
            );
            await conn.query(
                `INSERT INTO notifications
                 (notification_id, reader_id, title, content, type, reference_id, is_read, created_at)
                 VALUES (?, ?, ?, ?, 'system', ?, 0, NOW())`,
                [
                    uuidv4(),
                    reservation.reader_id,
                    'Slot nhận sách đã hết hạn',
                    `Thời hạn nhận sách "${reservation.book_title}" đã kết thúc. Bản sách đã được trả về trạng thái có sẵn.`,
                    reservation.reservation_id
                ]
            );
            expiredCount++;
        }
        await conn.commit();
        return { expired: expiredCount };
    } catch (error) {
        await conn.rollback();
        throw error;
    } finally {
        conn.release();
    }
};

