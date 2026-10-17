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

test('đăng ký chờ quá 14 ngày được hết hạn và xếp lại hàng chờ', async () => {
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
            if (sql.includes('SELECT hold_id FROM holds')) {
                return [[{ hold_id: 'hold-2' }, { hold_id: 'hold-3' }], []];
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
    assert.equal(committed, true);
    assert.ok(statements.some((sql) => sql.includes("SET status = 'expired'")));
    assert.equal(
        statements.filter((sql) => sql.includes('SET queue_position = ?')).length,
        2
    );
});
