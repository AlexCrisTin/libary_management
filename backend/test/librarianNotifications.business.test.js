const test = require('node:test');
const assert = require('node:assert/strict');

const dbPath = require.resolve('../src/config/db');
const calls = [];
const fakeDb = {
    query: async (sql, params = []) => {
        calls.push({ sql, params });
        if (sql.includes('COUNT(*) AS total')) return [[{ total: 6 }], []];
        return [[{
            notification_id: 'pickup:reservation-1',
            type: 'pickup_request',
            title: 'Yêu cầu đặt slot mới',
            reader_name: 'Nguyễn Văn A'
        }], []];
    }
};
require.cache[dbPath] = {
    id: dbPath,
    filename: dbPath,
    loaded: true,
    exports: fakeDb
};

const notificationsService = require('../src/modules/notifications/notifications.service');

test('thông báo thủ thư tổng hợp đủ các sự kiện nghiệp vụ', async () => {
    calls.length = 0;
    const result = await notificationsService.getLibrarianNotifications({
        page: 1,
        limit: 20
    });

    assert.equal(result.total, 6);
    assert.equal(result.data[0].type, 'pickup_request');
    assert.deepEqual(calls[1].params, [20, 0]);

    const sql = calls[0].sql;
    assert.match(sql, /pickup_reservations/);
    assert.match(sql, /FROM holds h/);
    assert.match(sql, /renewal_requests/);
    assert.match(sql, /borrow_transactions/);
    assert.match(sql, /chat_messages/);
    assert.match(sql, /unpaid_fine/);
    assert.doesNotMatch(sql, /FROM notifications n/);
});
