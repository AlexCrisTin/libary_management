const test = require('node:test');
const assert = require('node:assert/strict');

const dbPath = require.resolve('../src/config/db');
const fakeDb = {
    getConnection: async () => {
        throw new Error('Chưa cấu hình connection giả');
    }
};
require.cache[dbPath] = {
    id: dbPath,
    filename: dbPath,
    loaded: true,
    exports: fakeDb
};

const { scanAndExpireHolds } = require('../src/jobs/holdExpiration.job');

test('đăng ký báo khi có hết hạn mà không giữ hoặc chuyển lượt bản sao', async () => {
    const statements = [];
    let committed = false;
    const connection = {
        beginTransaction: async () => statements.push('BEGIN'),
        query: async (sql) => {
            statements.push(sql);
            if (sql.includes("WHERE status = 'waiting' AND expires_at")) {
                return [[{
                    hold_id: 'hold-expired',
                    reader_id: 'reader-1',
                    bib_id: 'book-1'
                }], []];
            }
            if (sql.includes("WHERE h.status = 'notified'")) return [[], []];
            return [{ affectedRows: 1 }, []];
        },
        commit: async () => { committed = true; },
        rollback: async () => {},
        release: () => statements.push('RELEASE')
    };
    fakeDb.getConnection = async () => connection;

    const result = await scanAndExpireHolds();

    assert.equal(result.waiting_expired, 1);
    assert.equal(result.notification_expired, 0);
    assert.equal(result.orphan_copies_released, 1);
    assert.equal(committed, true);
    assert.ok(statements.some((sql) => sql.includes("SET status = 'expired'")));
    assert.ok(statements.every((sql) => !sql.includes('SET queue_position = ?')));
    assert.ok(statements.some((sql) => sql.includes("bc.status = 'reserved'")));
});
