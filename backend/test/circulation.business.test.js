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

const circulationService = require('../src/modules/circulation/circulation.service');
const holdsService = require('../src/modules/holds/holds.service');

test('yêu cầu gia hạn không được vượt quá 7 ngày', async () => {
    let queried = false;
    fakeDb.query = async () => {
        queried = true;
        return [[], []];
    };

    await assert.rejects(
        circulationService.requestRenewal({
            tx_id: 'tx-1',
            reader_id: 'reader-1',
            requested_days: 8
        }),
        /1 đến 7 ngày/
    );
    assert.equal(queried, false);
});

test('chặn mượn sách khi thẻ độc giả đã hết hạn', async () => {
    fakeDb.query = async (sql) => {
        if (sql.includes('FROM readers')) {
            return [[{
                reader_id: 'reader-1',
                status: 'active',
                card_expired: '2020-01-01',
                max_books: 5
            }], []];
        }
        throw new Error('Không được truy vấn tiếp sau khi phát hiện thẻ hết hạn');
    };

    await assert.rejects(
        circulationService.borrowBook({ reader_id: 'reader-1', copy_id: 'copy-1' }),
        /đã hết hạn/
    );
});

test('chặn mượn khi độc giả đã đạt giới hạn số sách', async () => {
    let queryIndex = 0;
    fakeDb.query = async () => {
        queryIndex += 1;
        if (queryIndex === 1) {
            return [[{ reader_id: 'reader-1', status: 'active', card_expired: null, max_books: 2 }], []];
        }
        if (queryIndex === 2) return [[{ active_count: 2 }], []];
        throw new Error('Không được tra bản sao khi độc giả đã đạt giới hạn');
    };

    await assert.rejects(
        circulationService.borrowBook({ reader_id: 'reader-1', copy_id: 'copy-1' }),
        /mượn tối đa 2 cuốn/
    );
});

test('không cho mượn bản sách đang giữ theo slot của độc giả khác', async () => {
    let queryIndex = 0;
    fakeDb.query = async () => {
        queryIndex += 1;
        if (queryIndex === 1) {
            return [[{
                reader_id: 'reader-1',
                status: 'active',
                card_expired: null,
                max_books: 5
            }], []];
        }
        if (queryIndex === 2) return [[{ active_count: 0 }], []];
        if (queryIndex === 3) {
            return [[{
                copy_id: 'copy-1',
                bib_id: 'book-1',
                status: 'reserved',
                title: 'Sách thử nghiệm'
            }], []];
        }
        if (queryIndex === 4) {
            return [[{
                reservation_id: 'reservation-1',
                reader_id: 'reader-2',
                pickup_expires_at: new Date(Date.now() + 60 * 60 * 1000)
            }], []];
        }
        throw new Error('Không được truy vấn hàng chờ khi bản sách thuộc slot khác');
    };

    await assert.rejects(
        circulationService.borrowBook({ reader_id: 'reader-1', copy_id: 'copy-1' }),
        /slot của độc giả khác/
    );
});

test('không cho đặt trước khi vẫn còn bản sao sẵn sàng trên kệ', async () => {
    const responses = [
        [[{ reader_id: 'reader-1', status: 'active', card_expired: null }], []],
        [[{ bib_id: 'book-1', title: 'Sách thử nghiệm' }], []],
        [[], []],
        [[], []],
        [[{ total_copies: 2, available_copies: 1 }], []]
    ];
    fakeDb.query = async () => responses.shift();

    await assert.rejects(
        holdsService.createHold({ reader_id: 'reader-1', bib_id: 'book-1' }),
        /vẫn còn 1 cuốn sẵn sàng/
    );
});

test('đăng ký chờ sách có hiệu lực 14 ngày', async () => {
    const calls = [];
    const responses = [
        [[{ reader_id: 'reader-1', status: 'active', card_expired: null }], []],
        [[{ bib_id: 'book-1', title: 'Sách thử nghiệm' }], []],
        [[], []],
        [[], []],
        [[{ total_copies: 2, available_copies: 0 }], []],
        [[{ next_position: 1 }], []],
        [{ affectedRows: 1 }, []]
    ];
    fakeDb.query = async (sql, params) => {
        calls.push({ sql, params });
        return responses.shift();
    };

    const result = await holdsService.createHold({
        reader_id: 'reader-1',
        bib_id: 'book-1'
    });

    assert.equal(result.status, 'waiting');
    assert.equal(result.valid_days, 14);
    assert.ok(calls.some(({ sql }) => sql.includes('DATE_ADD(NOW(), INTERVAL 14 DAY)')));
});

test('lịch sử tiền phạt được tìm kiếm và phân trang ngay tại backend', async () => {
    const calls = [];
    fakeDb.query = async (sql, params) => {
        calls.push({ sql, params });
        if (sql.includes('COUNT(*) AS total')) return [[{ total: 41 }], []];
        return [[{ tx_id: 'tx-21', fine_amount: 5000 }], []];
    };

    const result = await circulationService.getLoanHistory({
        keyword: 'An',
        has_fine: true,
        page: 2,
        limit: 20
    });

    assert.equal(result.page, 2);
    assert.equal(result.total_pages, 3);
    assert.equal(result.data.length, 1);
    assert.ok(calls[0].sql.includes('bt.fine_amount > 0'));
    assert.ok(calls[0].sql.includes('r.full_name LIKE ?'));
    assert.deepEqual(calls[1].params.slice(-2), [20, 20]);
});

test('lọc quá hạn dùng ngày trả để khớp số liệu dashboard', async () => {
    const calls = [];
    fakeDb.query = async (sql, params) => {
        calls.push({ sql, params });
        if (sql.includes('COUNT(*) AS total')) return [[{ total: 1 }], []];
        return [[{
            tx_id: 'tx-overdue',
            status: 'borrowed',
            due_date: '2020-01-01',
            days_difference: 5
        }], []];
    };

    const result = await circulationService.getActiveLoans({
        status: 'overdue',
        page: 1,
        limit: 20
    });

    assert.equal(result.total, 1);
    assert.equal(result.data[0].is_overdue, true);
    assert.ok(calls[0].sql.includes('bt.due_date < CURDATE()'));
    assert.equal(calls[0].params.includes('overdue'), false);
});

test('lọc sắp hạn và quá hạn dùng cùng phạm vi 7 ngày với dashboard', async () => {
    const calls = [];
    fakeDb.query = async (sql, params) => {
        calls.push({ sql, params });
        if (sql.includes('COUNT(*) AS total')) return [[{ total: 2 }], []];
        return [[
            { tx_id: 'tx-overdue', due_date: '2020-01-01', days_difference: 2 },
            { tx_id: 'tx-due-soon', due_date: '2030-01-01', days_difference: -3 }
        ], []];
    };

    const result = await circulationService.getActiveLoans({
        status: 'attention',
        page: 1,
        limit: 20
    });

    assert.equal(result.total, 2);
    assert.ok(calls[0].sql.includes('bt.due_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)'));
    assert.equal(calls[0].params.includes('attention'), false);
});
