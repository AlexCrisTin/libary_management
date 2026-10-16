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
