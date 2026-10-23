const test = require('node:test');
const assert = require('node:assert/strict');

const dbPath = require.resolve('../src/config/db');
const calls = [];
const fakeDb = {
    query: async (sql, params = []) => {
        calls.push({ sql, params });
        if (sql.includes('AS pickup_count')) {
            return [[{
                pickup_count: 9995,
                renewal_count: 1,
                overdue_count: 1,
                fine_count: 1,
                message_count: 1
            }], []];
        }

        const sources = [
            ['FROM pickup_reservations pr', 'pickup:reservation-1', 'pickup_request', '2026-10-23T10:00:00Z'],
            ['FROM renewal_requests rr', 'renewal:request-1', 'renewal_request', '2026-10-23T08:00:00Z'],
            ["bt.status IN ('borrowed', 'overdue')", 'overdue:tx-1', 'overdue_loan', '2026-10-23T07:00:00Z'],
            ['bt.fine_paid = 0', 'fine:tx-2', 'unpaid_fine', '2026-10-23T06:00:00Z'],
            ['FROM chat_messages cm', 'message:reader-1', 'unread_message', '2026-10-23T05:00:00Z']
        ];
        const source = sources.find(([pattern]) => sql.includes(pattern));
        if (!source) throw new Error(`Câu SQL chưa được giả lập: ${sql}`);
        return [[{
            notification_id: source[1],
            type: source[2],
            title: 'Thông báo',
            reader_name: 'Nguyễn Văn A',
            created_at: source[3]
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

    assert.equal(result.total, 9999);
    assert.equal(result.total_pages, 500);
    assert.equal(result.data[0].type, 'pickup_request');
    assert.equal(result.data.length, 5);
    assert.equal(calls.length, 6);
    assert.ok(calls.slice(1).every(({ params }) => params.length === 1 && params[0] === 20));

    const allSql = calls.map(({ sql }) => sql).join('\n');
    assert.match(allSql, /pickup_reservations/);
    assert.doesNotMatch(allSql, /FROM holds h/);
    assert.match(allSql, /renewal_requests/);
    assert.match(allSql, /borrow_transactions/);
    assert.match(allSql, /chat_messages/);
    assert.match(allSql, /unpaid_fine/);
    assert.doesNotMatch(allSql, /UNION ALL/);
    assert.doesNotMatch(allSql, /FROM notifications n/);
});
