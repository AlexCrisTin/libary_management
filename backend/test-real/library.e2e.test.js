const path = require('path');
const { randomUUID } = require('crypto');
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const bcrypt = require('bcryptjs');

require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
process.env.NODE_ENV = 'test';
process.env.AUTOMATIONS_ENABLED = 'false';
process.env.DEV_OTP_ENABLED = 'true';

const app = require('../src/app');
const db = require('../src/config/db');

const suffix = `${Date.now()}${randomUUID().replaceAll('-', '').slice(0, 6)}`;
const shortSuffix = suffix.slice(-12);
const ids = {
    librarianUser: randomUUID(),
    readerUser1: randomUUID(),
    readerUser2: randomUUID(),
    reader1: randomUUID(),
    reader2: randomUUID(),
    bib1: randomUUID(),
    bib2: randomUUID(),
    copy1: randomUUID(),
    copy2: randomUUID(),
    notification1: randomUUID(),
    notification2: randomUUID()
};
const accounts = {
    librarian: { username: `e2e_lib_${suffix}`, password: 'TestLib@123' },
    reader1: { username: `e2e_r1_${suffix}`, password: 'TestReader@123' },
    reader2: { username: `e2e_r2_${suffix}`, password: 'TestReader@123' },
    registered: {
        username: `e2e_reg_${suffix}`,
        password: 'Register@123',
        email: `e2e.reg.${suffix}@example.test`
    }
};
const emails = {
    librarian: `e2e.lib.${suffix}@example.test`,
    reader1: `e2e.r1.${suffix}@example.test`,
    reader2: `e2e.r2.${suffix}@example.test`
};
const tracked = {
    registeredUser: null,
    registeredReader: null,
    txIds: [],
    reservationIds: []
};

let server;
let baseUrl;
let librarianToken;
let reader1Token;
let reader2Token;

const api = async (route, { method = 'GET', token, body, headers = {} } = {}) => {
    const requestHeaders = { ...headers };
    if (token) requestHeaders.Authorization = `Bearer ${token}`;
    if (body !== undefined) requestHeaders['Content-Type'] = 'application/json';
    const response = await fetch(`${baseUrl}${route}`, {
        method,
        headers: requestHeaders,
        body: body === undefined ? undefined : JSON.stringify(body)
    });
    const text = await response.text();
    let payload = null;
    if (text) {
        try {
            payload = JSON.parse(text);
        } catch {
            payload = text;
        }
    }
    return { status: response.status, body: payload, headers: response.headers };
};

const login = async (account) => {
    const response = await api('/api/auth/login', {
        method: 'POST',
        body: account
    });
    assert.equal(response.status, 200, JSON.stringify(response.body));
    assert.ok(response.body?.data?.token);
    return response.body.data.token;
};

before(async () => {
    const [librarianHash, readerHash] = await Promise.all([
        bcrypt.hash(accounts.librarian.password, 8),
        bcrypt.hash(accounts.reader1.password, 8)
    ]);
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();
        await connection.query(
            `INSERT INTO users
             (user_id, username, email, full_name, password_hash, role, is_active)
             VALUES (?, ?, ?, ?, ?, 'librarian', 1),
                    (?, ?, ?, ?, ?, 'reader', 1),
                    (?, ?, ?, ?, ?, 'reader', 1)`,
            [
                ids.librarianUser, accounts.librarian.username, emails.librarian, 'E2E Librarian', librarianHash,
                ids.readerUser1, accounts.reader1.username, emails.reader1, 'E2E Reader One', readerHash,
                ids.readerUser2, accounts.reader2.username, emails.reader2, 'E2E Reader Two', readerHash
            ]
        );
        await connection.query(
            `INSERT INTO readers
             (reader_id, user_id, reader_code, full_name, email, reader_type,
              card_issued, card_expired, status, max_books)
             VALUES (?, ?, ?, ?, ?, 'student', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR), 'active', 5),
                    (?, ?, ?, ?, ?, 'student', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR), 'active', 5)`,
            [
                ids.reader1, ids.readerUser1, `R1-${shortSuffix}`, 'E2E Reader One', emails.reader1,
                ids.reader2, ids.readerUser2, `R2-${shortSuffix}`, 'E2E Reader Two', emails.reader2
            ]
        );
        await connection.query(
            `INSERT INTO bibliographic_records
             (bib_id, isbn, title, authors, language, subject_headings, keywords)
             VALUES (?, ?, ?, ?, 'vi', ?, ?), (?, ?, ?, ?, 'vi', ?, ?)`,
            [
                ids.bib1, `E2EISBN1${suffix}`.slice(0, 20), `E2E Concurrent Book ${suffix}`,
                JSON.stringify([{ name: 'E2E Author', role: 'author' }]), JSON.stringify(['Testing']), JSON.stringify(['e2e']),
                ids.bib2, `E2EISBN2${suffix}`.slice(0, 20), `E2E Reserved Book ${suffix}`,
                JSON.stringify([{ name: 'E2E Author', role: 'author' }]), JSON.stringify(['Testing']), JSON.stringify(['e2e'])
            ]
        );
        await connection.query(
            `INSERT INTO book_copies
             (copy_id, bib_id, barcode, \`condition\`, status, acquired_date)
             VALUES (?, ?, ?, 'good', 'available', CURDATE()),
                    (?, ?, ?, 'good', 'available', CURDATE())`,
            [
                ids.copy1, ids.bib1, `E2E-C1-${suffix}`,
                ids.copy2, ids.bib2, `E2E-C2-${suffix}`
            ]
        );
        await connection.query(
            `INSERT INTO notifications
             (notification_id, reader_id, title, content, type, is_read)
             VALUES (?, ?, 'E2E reader one', 'Thông báo kiểm thử', 'system', 0),
                    (?, ?, 'E2E reader two', 'Thông báo kiểm thử', 'system', 0)`,
            [ids.notification1, ids.reader1, ids.notification2, ids.reader2]
        );
        await connection.commit();
    } catch (error) {
        await connection.rollback();
        throw error;
    } finally {
        connection.release();
    }

    await new Promise((resolve) => {
        server = app.listen(0, '127.0.0.1', resolve);
    });
    baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
    if (server) {
        await new Promise((resolve) => server.close(resolve));
    }

    const userIds = [ids.librarianUser, ids.readerUser1, ids.readerUser2];
    const readerIds = [ids.reader1, ids.reader2];
    if (tracked.registeredUser) userIds.push(tracked.registeredUser);
    if (tracked.registeredReader) readerIds.push(tracked.registeredReader);

    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();
        await connection.query('DELETE FROM password_resets WHERE email IN (?, ?, ?, ?)', [
            emails.librarian, emails.reader1, emails.reader2, accounts.registered.email
        ]);
        await connection.query(`DELETE FROM token_blacklist WHERE user_id IN (${userIds.map(() => '?').join(',')})`, userIds);
        await connection.query(`DELETE FROM notifications WHERE reader_id IN (${readerIds.map(() => '?').join(',')})`, readerIds);
        await connection.query(`DELETE FROM renewal_requests WHERE reader_id IN (${readerIds.map(() => '?').join(',')})`, readerIds);
        await connection.query(`DELETE FROM pickup_reservations WHERE reader_id IN (${readerIds.map(() => '?').join(',')})`, readerIds);
        await connection.query(`DELETE FROM holds WHERE reader_id IN (${readerIds.map(() => '?').join(',')})`, readerIds);
        await connection.query(`DELETE FROM chat_messages WHERE reader_id IN (${readerIds.map(() => '?').join(',')})`, readerIds);
        await connection.query(`DELETE FROM reader_bookmarks WHERE reader_id IN (${readerIds.map(() => '?').join(',')})`, readerIds);
        await connection.query(`DELETE FROM borrow_transactions WHERE reader_id IN (${readerIds.map(() => '?').join(',')})`, readerIds);
        await connection.query(`DELETE FROM reader_preferences WHERE reader_id IN (${readerIds.map(() => '?').join(',')})`, readerIds);
        await connection.query(`DELETE FROM readers WHERE reader_id IN (${readerIds.map(() => '?').join(',')})`, readerIds);
        await connection.query('DELETE FROM book_copies WHERE copy_id IN (?, ?)', [ids.copy1, ids.copy2]);
        await connection.query('DELETE FROM bibliographic_records WHERE bib_id IN (?, ?)', [ids.bib1, ids.bib2]);
        await connection.query(`DELETE FROM users WHERE user_id IN (${userIds.map(() => '?').join(',')})`, userIds);
        await connection.commit();

        const [leftovers] = await connection.query(
            `SELECT
                (SELECT COUNT(*) FROM users WHERE user_id IN (${userIds.map(() => '?').join(',')})) +
                (SELECT COUNT(*) FROM readers WHERE reader_id IN (${readerIds.map(() => '?').join(',')})) +
                (SELECT COUNT(*) FROM bibliographic_records WHERE bib_id IN (?, ?)) +
                (SELECT COUNT(*) FROM book_copies WHERE copy_id IN (?, ?)) AS total`,
            [...userIds, ...readerIds, ids.bib1, ids.bib2, ids.copy1, ids.copy2]
        );
        assert.equal(Number(leftovers[0].total), 0, 'Dữ liệu E2E phải được dọn sạch hoàn toàn');
    } catch (error) {
        await connection.rollback();
        throw error;
    } finally {
        connection.release();
        await db.end();
    }
});

test('luồng xuyên suốt trên MySQL thật và hàng rào bảo mật tối thiểu', async (t) => {
    await t.test('đăng nhập, phân quyền và cô lập dữ liệu độc giả', async () => {
        const unauthenticated = await api('/api/auth/me');
        assert.equal(unauthenticated.status, 401);

        librarianToken = await login(accounts.librarian);
        reader1Token = await login(accounts.reader1);
        reader2Token = await login(accounts.reader2);

        const forbiddenAdmin = await api('/api/users', { token: reader1Token });
        assert.equal(forbiddenAdmin.status, 403);

        const otherReader = await api(`/api/readers/${ids.reader2}`, { token: reader1Token });
        assert.equal(otherReader.status, 403);

        const isbnLookup = await api('/api/books/lookup-isbn/9780132350884', { token: reader1Token });
        assert.equal(isbnLookup.status, 403);

        const raiseLimit = await api(`/api/readers/${ids.reader1}`, {
            method: 'PUT',
            token: reader1Token,
            body: { max_books: 50 }
        });
        assert.equal(raiseLimit.status, 400);
        const [readerRows] = await db.query('SELECT max_books FROM readers WHERE reader_id = ?', [ids.reader1]);
        assert.equal(Number(readerRows[0].max_books), 5);

        const duplicateEmail = await api(`/api/readers/${ids.reader1}`, {
            method: 'PUT',
            token: reader1Token,
            body: { email: emails.reader2 }
        });
        assert.equal(duplicateEmail.status, 400);
        const [emailRows] = await db.query('SELECT email FROM readers WHERE reader_id = ?', [ids.reader1]);
        assert.equal(emailRows[0].email, emails.reader1);

        const notifications = await api(`/api/notifications?reader_id=${ids.reader2}`, { token: reader1Token });
        assert.equal(notifications.status, 200);
        assert.ok(notifications.body.data.data.every((item) => item.reader_id === ids.reader1));
        assert.ok(notifications.body.data.data.some((item) => item.notification_id === ids.notification1));
        assert.ok(!notifications.body.data.data.some((item) => item.notification_id === ids.notification2));

        const cappedPage = await api('/api/books?page=1&limit=100000');
        assert.equal(cappedPage.status, 200);
        assert.equal(cappedPage.body.data.limit, 100);

        const blockedOrigin = await api('/health', { headers: { Origin: 'https://evil.invalid' } });
        assert.equal(blockedOrigin.status, 403);
    });

    await t.test('đăng ký và OTP dùng dữ liệu thật nhưng không lưu mã rõ', async () => {
        const registration = await api('/api/auth/register', {
            method: 'POST',
            body: {
                username: accounts.registered.username,
                password: accounts.registered.password,
                full_name: 'E2E Registered Reader',
                email: accounts.registered.email
            }
        });
        assert.equal(registration.status, 201, JSON.stringify(registration.body));
        tracked.registeredUser = registration.body.data.user.user_id;
        tracked.registeredReader = registration.body.data.user.reader_id;

        const unknownEmail = await api('/api/auth/forgot-password', {
            method: 'POST',
            body: { email: `missing.${suffix}@example.test` }
        });
        assert.equal(unknownEmail.status, 200);
        assert.equal(unknownEmail.body.data.dev_otp, undefined);

        const forgot = await api('/api/auth/forgot-password', {
            method: 'POST',
            body: { email: emails.reader2 }
        });
        assert.equal(forgot.status, 200, JSON.stringify(forgot.body));
        const otp = forgot.body.data.dev_otp;
        assert.match(otp, /^\d{6}$/);
        const [resetRows] = await db.query('SELECT otp FROM password_resets WHERE email = ?', [emails.reader2]);
        assert.equal(resetRows[0].otp.length, 64);
        assert.notEqual(resetRows[0].otp, otp);

        const reset = await api('/api/auth/reset-password', {
            method: 'POST',
            body: { email: emails.reader2, otp, new_password: 'ReaderNew@123' }
        });
        assert.equal(reset.status, 200, JSON.stringify(reset.body));
        const reusedOtp = await api('/api/auth/reset-password', {
            method: 'POST',
            body: { email: emails.reader2, otp, new_password: 'ShouldNotApply@123' }
        });
        assert.equal(reusedOtp.status, 400);
        const staleToken = await api('/api/auth/me', { token: reader2Token });
        assert.equal(staleToken.status, 401);
        reader2Token = await login({ username: accounts.reader2.username, password: 'ReaderNew@123' });
    });

    await t.test('từ chối file giả mạo ảnh', async () => {
        const form = new FormData();
        form.append('file', new Blob([Buffer.from('not a real png')], { type: 'image/png' }), 'fake.png');
        const response = await fetch(`${baseUrl}/api/uploads/book-cover`, {
            method: 'POST',
            headers: { Authorization: `Bearer ${librarianToken}` },
            body: form
        });
        assert.equal(response.status, 400);
    });

    await t.test('mượn đồng thời, gia hạn có duyệt, trả và thu phạt', async () => {
        const borrowRequest = () => api('/api/circulation/borrow', {
            method: 'POST',
            token: librarianToken,
            body: { reader_id: ids.reader1, copy_id: ids.copy1, due_days: 14 }
        });
        const attempts = await Promise.all([borrowRequest(), borrowRequest()]);
        assert.deepEqual(attempts.map((item) => item.status).sort(), [201, 400]);
        const borrowed = attempts.find((item) => item.status === 201);
        const txId = borrowed.body.data.tx_id;
        tracked.txIds.push(txId);

        const [copyRows] = await db.query('SELECT status FROM book_copies WHERE copy_id = ?', [ids.copy1]);
        assert.equal(copyRows[0].status, 'borrowed');

        const forbiddenRenewal = await api(`/api/circulation/renew/${txId}`, {
            method: 'POST', token: reader2Token, body: { extend_days: 3 }
        });
        assert.equal(forbiddenRenewal.status, 400);

        const renewal = await api(`/api/circulation/renew/${txId}`, {
            method: 'POST', token: reader1Token, body: { extend_days: 3 }
        });
        assert.equal(renewal.status, 201, JSON.stringify(renewal.body));
        const approval = await api(`/api/circulation/renew-requests/${renewal.body.data.request_id}`, {
            method: 'PUT', token: librarianToken, body: { action: 'approve', extend_days: 5 }
        });
        assert.equal(approval.status, 200, JSON.stringify(approval.body));
        assert.equal(approval.body.data.approved_days, 5);

        await db.query(
            "UPDATE borrow_transactions SET due_date = DATE_SUB(CURDATE(), INTERVAL 1 DAY), status = 'borrowed' WHERE tx_id = ?",
            [txId]
        );
        const returned = await api('/api/circulation/return', {
            method: 'POST', token: librarianToken, body: { tx_id: txId }
        });
        assert.equal(returned.status, 200, JSON.stringify(returned.body));
        assert.equal(Number(returned.body.data.fine_amount), 2000);

        const paid = await api(`/api/circulation/${txId}/pay-fine`, {
            method: 'PUT', token: librarianToken, body: {}
        });
        assert.equal(paid.status, 200, JSON.stringify(paid.body));
        const [txRows] = await db.query(
            'SELECT status, fine_amount, fine_paid FROM borrow_transactions WHERE tx_id = ?',
            [txId]
        );
        assert.equal(txRows[0].status, 'returned');
        assert.equal(Number(txRows[0].fine_amount), 2000);
        assert.equal(Number(txRows[0].fine_paid), 1);
    });

    await t.test('báo khi có chuyển thành đặt slot khi sách được trả', async () => {
        const borrowed = await api('/api/circulation/borrow', {
            method: 'POST', token: librarianToken,
            body: { reader_id: ids.reader2, copy_id: ids.copy1, due_days: 14 }
        });
        assert.equal(borrowed.status, 201, JSON.stringify(borrowed.body));
        const borrowedTxId = borrowed.body.data.tx_id;
        tracked.txIds.push(borrowedTxId);

        const hold = await api('/api/holds', {
            method: 'POST', token: reader1Token, body: { bib_id: ids.bib1 }
        });
        assert.equal(hold.status, 201, JSON.stringify(hold.body));
        const holdId = hold.body.data.hold_id;

        const returned = await api('/api/circulation/return', {
            method: 'POST', token: librarianToken, body: { tx_id: borrowedTxId }
        });
        assert.equal(returned.status, 200, JSON.stringify(returned.body));
        assert.equal(returned.body.data.book.next_status, 'available');
        assert.ok(
            returned.body.data.hold_notifications.some(
                (item) => item.hold_id === holdId && item.reader_id === ids.reader1
            ),
            'Trả sách phải tạo sự kiện thông báo báo khi có cho độc giả'
        );
        const [availabilityNotices] = await db.query(
            `SELECT notification_id FROM notifications
             WHERE reader_id = ? AND reference_id = ? AND type = 'hold_available'`,
            [ids.reader1, holdId]
        );
        assert.equal(
            availabilityNotices.length,
            1,
            'Thông báo sách có lại phải xuất hiện trong notice của độc giả'
        );

        const slot = await api('/api/pickup-reservations', {
            method: 'POST', token: reader1Token,
            body: { bib_id: ids.bib1, hold_id: holdId }
        });
        assert.equal(slot.status, 201, JSON.stringify(slot.body));
        assert.equal(slot.body.data.converted_from_waitlist, true);
        assert.equal(slot.body.data.copy_id, null);
        const reservationId = slot.body.data.reservation_id;
        tracked.reservationIds.push(reservationId);

        const pendingForLibrarian = await api(
            `/api/pickup-reservations?status=pending&reader_id=${encodeURIComponent(ids.reader1)}`,
            { token: librarianToken }
        );
        assert.equal(pendingForLibrarian.status, 200, JSON.stringify(pendingForLibrarian.body));
        assert.ok(
            pendingForLibrarian.body.data.data.some(
                (item) => item.reservation_id === reservationId && item.copy_id === null
            ),
            'Yêu cầu đặt slot phải xuất hiện cho thủ thư nhưng chưa giữ bản sao trước khi duyệt'
        );

        const [holdRows] = await db.query(
            'SELECT status FROM holds WHERE hold_id = ?',
            [holdId]
        );
        assert.equal(holdRows[0].status, 'fulfilled');

        const expiry = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString();
        const approved = await api(`/api/pickup-reservations/${reservationId}/approve`, {
            method: 'PUT', token: librarianToken, body: { pickup_expires_at: expiry }
        });
        assert.equal(approved.status, 200, JSON.stringify(approved.body));
        assert.equal(approved.body.data.copy_id, ids.copy1);

        const approvedForBorrowFlow = await api(
            `/api/pickup-reservations?status=approved&reader_id=${encodeURIComponent(ids.reader1)}`,
            { token: librarianToken }
        );
        assert.equal(approvedForBorrowFlow.status, 200, JSON.stringify(approvedForBorrowFlow.body));
        assert.ok(
            approvedForBorrowFlow.body.data.data.some(
                (item) => item.reservation_id === reservationId && item.barcode
            ),
            'Slot đã duyệt phải trả về barcode bản sao cho luồng lập phiếu mượn'
        );

        const received = await api('/api/circulation/borrow', {
            method: 'POST', token: librarianToken,
            body: { reader_id: ids.reader1, copy_id: ids.copy1, due_days: 14 }
        });
        assert.equal(received.status, 201, JSON.stringify(received.body));
        tracked.txIds.push(received.body.data.tx_id);
    });

    await t.test('đặt slot, duyệt đúng bản sao và chỉ người đặt được mượn', async () => {
        const reservation = await api('/api/pickup-reservations', {
            method: 'POST', token: reader1Token, body: { bib_id: ids.bib2 }
        });
        assert.equal(reservation.status, 201, JSON.stringify(reservation.body));
        const reservationId = reservation.body.data.reservation_id;
        tracked.reservationIds.push(reservationId);

        const expiry = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString();
        const approved = await api(`/api/pickup-reservations/${reservationId}/approve`, {
            method: 'PUT', token: librarianToken, body: { pickup_expires_at: expiry }
        });
        assert.equal(approved.status, 200, JSON.stringify(approved.body));
        assert.equal(approved.body.data.copy_id, ids.copy2);

        const wrongReader = await api('/api/circulation/borrow', {
            method: 'POST', token: librarianToken,
            body: { reader_id: ids.reader2, copy_id: ids.copy2, due_days: 14 }
        });
        assert.equal(wrongReader.status, 400);

        const rightReader = await api('/api/circulation/borrow', {
            method: 'POST', token: librarianToken,
            body: { reader_id: ids.reader1, copy_id: ids.copy2, due_days: 14 }
        });
        assert.equal(rightReader.status, 201, JSON.stringify(rightReader.body));
        tracked.txIds.push(rightReader.body.data.tx_id);
        const [rows] = await db.query(
            'SELECT status FROM pickup_reservations WHERE reservation_id = ?',
            [reservationId]
        );
        assert.equal(rows[0].status, 'fulfilled');
    });

    await t.test('khóa tài khoản, đổi mật khẩu và đăng xuất vô hiệu hóa token cũ', async () => {
        await db.query('UPDATE users SET is_active = 0 WHERE user_id = ?', [ids.readerUser1]);
        const locked = await api('/api/auth/me', { token: reader1Token });
        assert.equal(locked.status, 401);
        await db.query('UPDATE users SET is_active = 1 WHERE user_id = ?', [ids.readerUser1]);

        const activeAgain = await api('/api/auth/me', { token: reader1Token });
        assert.equal(activeAgain.status, 200);
        const changed = await api('/api/auth/change-password', {
            method: 'PUT', token: reader1Token,
            body: { oldPassword: accounts.reader1.password, newPassword: 'ReaderOneNew@123' }
        });
        assert.equal(changed.status, 200, JSON.stringify(changed.body));
        const passwordStale = await api('/api/auth/me', { token: reader1Token });
        assert.equal(passwordStale.status, 401);

        reader1Token = await login({ username: accounts.reader1.username, password: 'ReaderOneNew@123' });
        const loggedOut = await api('/api/auth/logout', {
            method: 'POST', token: reader1Token, body: {}
        });
        assert.equal(loggedOut.status, 200, JSON.stringify(loggedOut.body));
        const [blacklistRows] = await db.query(
            'SELECT token FROM token_blacklist WHERE user_id = ? ORDER BY id DESC LIMIT 1',
            [ids.readerUser1]
        );
        assert.equal(blacklistRows[0].token.length, 64);
        assert.notEqual(blacklistRows[0].token, reader1Token);
        const revoked = await api('/api/auth/me', { token: reader1Token });
        assert.equal(revoked.status, 401);
    });
});
