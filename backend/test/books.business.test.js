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

const booksService = require('../src/modules/books/books.service');

const connectionFor = ({ copy, history = [] }) => {
    const statements = [];
    let committed = false;
    let rolledBack = false;
    const connection = {
        beginTransaction: async () => statements.push('BEGIN'),
        query: async (sql) => {
            statements.push(sql);
            if (sql.includes('FROM book_copies') && sql.includes('FOR UPDATE')) {
                return [copy ? [copy] : [], []];
            }
            if (sql.includes('FROM borrow_transactions')) return [history, []];
            if (sql.startsWith('DELETE FROM book_copies')) return [{ affectedRows: 1 }, []];
            throw new Error(`Câu SQL chưa được giả lập: ${sql}`);
        },
        commit: async () => { committed = true; },
        rollback: async () => { rolledBack = true; },
        release: () => statements.push('RELEASE')
    };
    return {
        connection,
        statements,
        get committed() { return committed; },
        get rolledBack() { return rolledBack; }
    };
};

test('xóa được bản sao khả dụng chưa có lịch sử mượn', async () => {
    const state = connectionFor({
        copy: { copy_id: 'copy-1', bib_id: 'book-1', barcode: 'BC-001', status: 'available' }
    });
    fakeDb.getConnection = async () => state.connection;

    const deleted = await booksService.deleteCopy('copy-1');

    assert.equal(deleted.copy_id, 'copy-1');
    assert.equal(state.committed, true);
    assert.equal(state.rolledBack, false);
    assert.ok(state.statements.some((sql) => sql.startsWith('DELETE FROM book_copies')));
});

test('chặn xóa bản sao đang được mượn', async () => {
    const state = connectionFor({
        copy: { copy_id: 'copy-2', bib_id: 'book-1', barcode: 'BC-002', status: 'borrowed' }
    });
    fakeDb.getConnection = async () => state.connection;

    await assert.rejects(
        booksService.deleteCopy('copy-2'),
        (error) => error.code === 'COPY_IN_USE'
    );
    assert.equal(state.rolledBack, true);
    assert.equal(state.committed, false);
});

test('chặn xóa bản sao đã có lịch sử mượn trả', async () => {
    const state = connectionFor({
        copy: { copy_id: 'copy-3', bib_id: 'book-1', barcode: 'BC-003', status: 'available' },
        history: [{ tx_id: 'tx-1' }]
    });
    fakeDb.getConnection = async () => state.connection;

    await assert.rejects(
        booksService.deleteCopy('copy-3'),
        (error) => error.code === 'COPY_HAS_HISTORY'
    );
    assert.equal(state.rolledBack, true);
    assert.equal(state.committed, false);
});

test('lưu và bỏ lưu sách là thao tác idempotent theo độc giả', async () => {
    const calls = [];
    fakeDb.query = async (sql, params) => {
        calls.push({ sql, params });
        if (sql.includes('FROM bibliographic_records')) return [[{ bib_id: 'book-1' }], []];
        return [{ affectedRows: 1 }, []];
    };

    const saved = await booksService.addBookmark({ reader_id: 'reader-1', bib_id: 'book-1' });
    const removed = await booksService.removeBookmark({ reader_id: 'reader-1', bib_id: 'book-1' });

    assert.equal(saved.bookmarked, true);
    assert.equal(removed.bookmarked, false);
    assert.ok(calls.some(({ sql }) => sql.includes('INSERT IGNORE INTO reader_bookmarks')));
    assert.ok(calls.some(({ sql }) => sql.includes('DELETE FROM reader_bookmarks')));
});
