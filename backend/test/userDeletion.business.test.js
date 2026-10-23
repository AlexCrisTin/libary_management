const test = require('node:test');
const assert = require('node:assert/strict');

const dbPath = require.resolve('../src/config/db');
const fakeDb = {
    query: async () => [[], []],
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

const usersService = require('../src/modules/users/users.service');
const readersService = require('../src/modules/readers/readers.service');

test('xóa tài khoản sẽ lưu trữ hồ sơ độc giả và giải phóng đặt slot', async () => {
    const statements = [];
    let committed = false;
    const connection = {
        beginTransaction: async () => statements.push('BEGIN'),
        query: async (sql) => {
            statements.push(sql);
            if (sql.includes('FROM users u')) {
                return [[{ user_id: 'user-1', role: 'reader', reader_id: 'reader-1' }], []];
            }
            if (sql.includes('FROM borrow_transactions')) return [[], []];
            if (sql.includes('DELETE FROM users')) return [{ affectedRows: 1 }, []];
            return [{ affectedRows: 1 }, []];
        },
        commit: async () => { committed = true; },
        rollback: async () => {},
        release: () => statements.push('RELEASE')
    };
    fakeDb.getConnection = async () => connection;

    const deleted = await usersService.deleteUser('user-1');

    assert.equal(deleted, true);
    assert.equal(committed, true);
    assert.ok(statements.some((sql) => sql.includes("SET status = 'cancelled'")));
    assert.ok(statements.some((sql) => sql.includes('archived_at = NOW()')));
    assert.ok(statements.some((sql) => sql.includes('DELETE FROM users')));
});

test('không xóa tài khoản độc giả khi còn sách chưa trả', async () => {
    const statements = [];
    let rolledBack = false;
    const connection = {
        beginTransaction: async () => {},
        query: async (sql) => {
            statements.push(sql);
            if (sql.includes('FROM users u')) {
                return [[{ user_id: 'user-1', role: 'reader', reader_id: 'reader-1' }], []];
            }
            if (sql.includes('FROM borrow_transactions')) {
                return [[{ tx_id: 'tx-active' }], []];
            }
            return [{ affectedRows: 1 }, []];
        },
        commit: async () => {},
        rollback: async () => { rolledBack = true; },
        release: () => {}
    };
    fakeDb.getConnection = async () => connection;

    await assert.rejects(
        usersService.deleteUser('user-1'),
        /còn sách chưa trả/
    );
    assert.equal(rolledBack, true);
    assert.equal(statements.some((sql) => sql.includes('DELETE FROM users')), false);
});

test('danh sách quản lý độc giả không lấy hồ sơ đã lưu trữ', async () => {
    const statements = [];
    fakeDb.query = async (sql) => {
        statements.push(sql);
        if (sql.includes('COUNT(*) AS total')) return [[{ total: 0 }], []];
        return [[], []];
    };

    const result = await readersService.getAllReaders({});

    assert.equal(result.total, 0);
    assert.equal(statements.length, 2);
    assert.ok(statements.every((sql) => sql.includes('r.archived_at IS NULL')));
});
