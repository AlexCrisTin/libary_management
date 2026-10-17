const test = require('node:test');
const assert = require('node:assert/strict');

const dbPath = require.resolve('../src/config/db');
const calls = [];
const fakeDb = {
    query: async (sql) => {
        calls.push(sql);
        if (sql.includes('AS active_loans')) {
            return [[{
                active_loans: 2,
                overdue_loans: 1,
                total_readers: 3,
                total_titles: 4,
                total_copies: 5,
                unpaid_fines: 0
            }], []];
        }
        if (sql.includes('borrow_date AS event_date')) return [[], []];
        if (sql.includes('return_date AS event_date')) return [[], []];
        if (sql.includes('b.subject_headings')) return [[], []];
        if (sql.includes('ORDER BY borrow_count DESC') && sql.includes('br.title')) return [[], []];
        if (sql.includes('ORDER BY borrow_count DESC') && sql.includes('r.full_name')) return [[], []];
        if (sql.includes('DATEDIFF(bt.due_date')) {
            return [[
                {
                    tx_id: 'tx-overdue',
                    due_date: '2026-10-15',
                    status: 'borrowed',
                    days_until_due: -2,
                    reader_id: 'reader-1',
                    full_name: 'Nguyễn Văn A',
                    reader_code: 'R001',
                    bib_id: 'book-1',
                    title: 'Clean Code',
                    barcode: 'BC001'
                },
                {
                    tx_id: 'tx-soon',
                    due_date: '2026-10-19',
                    status: 'borrowed',
                    days_until_due: 2,
                    reader_id: 'reader-2',
                    full_name: 'Trần Thị B',
                    reader_code: 'R002',
                    bib_id: 'book-2',
                    title: 'Flutter Pro',
                    barcode: 'BC002'
                }
            ], []];
        }
        throw new Error(`Câu SQL chưa được giả lập: ${sql}`);
    }
};
require.cache[dbPath] = {
    id: dbPath,
    filename: dbPath,
    loaded: true,
    exports: fakeDb
};

const dashboardService = require('../src/modules/dashboard/dashboard.service');

test('dashboard ưu tiên lượt quá hạn rồi đến lượt sắp hết hạn', async () => {
    const result = await dashboardService.getStatistics({ days: 7 });

    assert.equal(result.due_soon_loans.length, 2);
    assert.equal(result.due_soon_loans[0].tx_id, 'tx-overdue');
    assert.equal(result.due_soon_loans[0].is_overdue, true);
    assert.equal(result.due_soon_loans[1].days_until_due, 2);
    assert.equal(result.due_soon_loans[1].is_overdue, false);

    const dueQuery = calls.find((sql) => sql.includes('DATEDIFF(bt.due_date'));
    assert.ok(dueQuery.includes('DATE_ADD(CURDATE(), INTERVAL 7 DAY)'));
    assert.ok(dueQuery.includes('CASE WHEN bt.due_date < CURDATE() THEN 0 ELSE 1 END'));
});
