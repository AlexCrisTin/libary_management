const test = require('node:test');
const assert = require('node:assert/strict');

const dbPath = require.resolve('../src/config/db');
const fakeDb = { query: async () => [[], []] };
require.cache[dbPath] = {
    id: dbPath,
    filename: dbPath,
    loaded: true,
    exports: fakeDb
};

const { scanAndNotifyOverdue } = require('../src/jobs/overdueNotification.job');
const { scanAndNotifyCardExpiration } = require('../src/jobs/cardExpirationNotification.job');

test('tự động đánh dấu quá hạn và tạo thông báo nhắc trả trước hai ngày', async () => {
    const calls = [];
    fakeDb.query = async (sql, params = []) => {
        calls.push({ sql, params });
        if (sql.includes('DATEDIFF(CURDATE(), bt.due_date)')) {
            return [[{
                tx_id: 'tx-overdue',
                reader_id: 'reader-1',
                copy_id: 'copy-1',
                due_date: '2026-10-15',
                status: 'borrowed',
                days_overdue: 2,
                barcode: 'BC001',
                book_title: 'Clean Code'
            }], []];
        }
        if (sql.includes('DATEDIFF(bt.due_date, CURDATE())')) {
            return [[{
                tx_id: 'tx-soon',
                reader_id: 'reader-2',
                due_date: '2026-10-19',
                days_left: 2,
                barcode: 'BC002',
                book_title: 'Flutter Pro'
            }], []];
        }
        if (sql.includes('SELECT notification_id FROM notifications')) return [[], []];
        return [{ affectedRows: 1 }, []];
    };

    const result = await scanAndNotifyOverdue();

    assert.deepEqual(result, {
        scanned_overdue: 1,
        overdue_updated: 1,
        overdue_notified: 1,
        scanned_due_soon: 1,
        due_soon_notified: 1
    });
    assert.ok(calls.some(({ sql }) => sql.includes('SET status = "overdue"')));
    assert.ok(calls.some(({ sql }) => sql.includes("'overdue'")));
    assert.ok(calls.some(({ sql }) => sql.includes("'due_soon'")));
});

test('tự động cập nhật thẻ hết hạn và chống trùng thông báo theo từng kỳ hạn thẻ', async () => {
    const insertedReferences = [];
    fakeDb.query = async (sql, params = []) => {
        if (sql.includes('FROM readers')) {
            return [[
                {
                    reader_id: 'reader-expired',
                    full_name: 'Nguyễn Văn A',
                    card_expired: '2026-10-16',
                    status: 'active',
                    days_left: -1
                },
                {
                    reader_id: 'reader-soon',
                    full_name: 'Trần Thị B',
                    card_expired: '2026-10-22',
                    status: 'active',
                    days_left: 5
                }
            ], []];
        }
        if (sql.includes('SELECT notification_id FROM notifications')) return [[], []];
        if (sql.includes('INSERT INTO notifications')) {
            insertedReferences.push(params[4]);
        }
        return [{ affectedRows: 1 }, []];
    };

    const result = await scanAndNotifyCardExpiration();

    assert.equal(result.scanned, 2);
    assert.equal(result.expired_updated, 1);
    assert.equal(result.notified, 2);
    assert.equal(insertedReferences.length, 2);
    assert.ok(insertedReferences.every((value) => value.length === 36));
    assert.notEqual(insertedReferences[0], insertedReferences[1]);
    assert.ok(!insertedReferences.includes('reader-expired'));
});
