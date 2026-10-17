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

const service = require('../src/modules/pickupReservations/pickupReservations.service');

test('tạo yêu cầu đặt slot khi sách còn bản có sẵn', async () => {
    const calls = [];
    fakeDb.query = async (sql, params) => {
        calls.push({ sql, params });
        if (sql.includes('FROM readers')) {
            return [[{ reader_id: 'reader-1', status: 'active', card_expired: null }], []];
        }
        if (sql.includes('FROM bibliographic_records')) {
            return [[{ bib_id: 'book-1', title: 'Sách thử nghiệm', isbn: '123' }], []];
        }
        if (sql.includes('FROM borrow_transactions')) return [[], []];
        if (sql.includes('FROM pickup_reservations')) return [[], []];
        if (sql.includes('FROM holds')) return [[], []];
        if (sql.includes('COUNT(*) AS available_copies')) {
            return [[{ available_copies: 2 }], []];
        }
        if (sql.includes('INSERT INTO pickup_reservations')) return [{ affectedRows: 1 }, []];
        throw new Error(`Câu SQL chưa được giả lập: ${sql}`);
    };

    const result = await service.createReservation({
        reader_id: 'reader-1',
        bib_id: 'book-1'
    });

    assert.equal(result.status, 'pending');
    assert.equal(result.book_title, 'Sách thử nghiệm');
    assert.ok(calls.some(({ sql }) => sql.includes('INSERT INTO pickup_reservations')));
});

test('không tạo slot nếu sách vừa hết bản có sẵn', async () => {
    fakeDb.query = async (sql) => {
        if (sql.includes('FROM readers')) {
            return [[{ reader_id: 'reader-1', status: 'active', card_expired: null }], []];
        }
        if (sql.includes('FROM bibliographic_records')) {
            return [[{ bib_id: 'book-1', title: 'Sách thử nghiệm' }], []];
        }
        if (sql.includes('FROM borrow_transactions')) return [[], []];
        if (sql.includes('FROM pickup_reservations')) return [[], []];
        if (sql.includes('FROM holds')) return [[], []];
        if (sql.includes('COUNT(*) AS available_copies')) {
            return [[{ available_copies: 0 }], []];
        }
        throw new Error(`Câu SQL chưa được giả lập: ${sql}`);
    };

    await assert.rejects(
        service.createReservation({ reader_id: 'reader-1', bib_id: 'book-1' }),
        /hết bản có sẵn/
    );
});

test('duyệt slot sẽ khóa một bản sách và tạo thông báo', async () => {
    const statements = [];
    let committed = false;
    const connection = {
        beginTransaction: async () => statements.push('BEGIN'),
        query: async (sql) => {
            statements.push(sql);
            if (sql.includes('FROM pickup_reservations pr')) {
                return [[{
                    reservation_id: 'reservation-1',
                    reader_id: 'reader-1',
                    bib_id: 'book-1',
                    status: 'pending',
                    book_title: 'Sách thử nghiệm'
                }], []];
            }
            if (sql.includes('FROM book_copies')) {
                return [[{ copy_id: 'copy-1', barcode: 'BC-001' }], []];
            }
            return [{ affectedRows: 1 }, []];
        },
        commit: async () => { committed = true; },
        rollback: async () => {},
        release: () => statements.push('RELEASE')
    };
    fakeDb.getConnection = async () => connection;

    const result = await service.approveReservation({
        reservation_id: 'reservation-1',
        pickup_expires_at: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(),
        processed_by: 'librarian-1'
    });

    assert.equal(result.status, 'approved');
    assert.equal(result.copy_id, 'copy-1');
    assert.equal(committed, true);
    assert.ok(statements.some((sql) => sql.includes("SET status = 'reserved'")));
    assert.ok(statements.some((sql) => sql.includes('INSERT INTO notifications')));
});

test('không cho thủ thư đặt thời hạn lấy sách quá 7 ngày', async () => {
    let requestedConnection = false;
    fakeDb.getConnection = async () => {
        requestedConnection = true;
        throw new Error('Không được mở transaction');
    };

    await assert.rejects(
        service.approveReservation({
            reservation_id: 'reservation-1',
            pickup_expires_at: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000).toISOString(),
            processed_by: 'librarian-1'
        }),
        /không được vượt quá 7 ngày/
    );
    assert.equal(requestedConnection, false);
});
