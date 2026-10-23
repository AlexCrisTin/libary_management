const path = require('path');
const { randomUUID } = require('crypto');
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const bcrypt = require('bcryptjs');

require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const db = require('../src/config/db');
const booksService = require('../src/modules/books/books.service');

const ids = {
    user: randomUUID(),
    reader: randomUUID(),
    bib: randomUUID(),
    copy: randomUUID(),
    transaction: randomUUID()
};
const suffix = randomUUID().replaceAll('-', '').slice(0, 10).toUpperCase();

before(async () => {
    const passwordHash = await bcrypt.hash('DeleteBook@123', 8);
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();
        await connection.query(
            `INSERT INTO users
             (user_id, username, full_name, password_hash, role, is_active)
             VALUES (?, ?, 'E2E Book Delete Reader', ?, 'reader', 1)`,
            [ids.user, `e2e_book_delete_${suffix}`, passwordHash]
        );
        await connection.query(
            `INSERT INTO readers
             (reader_id, user_id, reader_code, full_name, reader_type,
              card_issued, card_expired, status, max_books)
             VALUES (?, ?, ?, 'E2E Book Delete Reader', 'student',
                     CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR), 'active', 5)`,
            [ids.reader, ids.user, `RD-${suffix}`]
        );
        await connection.query(
            `INSERT INTO bibliographic_records
             (bib_id, isbn, title, authors, language)
             VALUES (?, ?, ?, '[]', 'vi')`,
            [ids.bib, `DEL${suffix}`, `E2E Archived Book ${suffix}`]
        );
        await connection.query(
            `INSERT INTO book_copies
             (copy_id, bib_id, barcode, \`condition\`, status, acquired_date)
             VALUES (?, ?, ?, 'good', 'available', CURDATE())`,
            [ids.copy, ids.bib, `DEL-COPY-${suffix}`]
        );
        await connection.query(
            `INSERT INTO borrow_transactions
             (tx_id, reader_id, copy_id, borrow_date, due_date, return_date,
              status, fine_amount, fine_paid)
             VALUES (?, ?, ?, DATE_SUB(CURDATE(), INTERVAL 20 DAY),
                     DATE_SUB(CURDATE(), INTERVAL 6 DAY),
                     DATE_SUB(CURDATE(), INTERVAL 7 DAY), 'returned', 0, 1)`,
            [ids.transaction, ids.reader, ids.copy]
        );
        await connection.commit();
    } catch (error) {
        await connection.rollback();
        throw error;
    } finally {
        connection.release();
    }
});

after(async () => {
    await db.query('DELETE FROM borrow_transactions WHERE tx_id = ?', [ids.transaction]);
    await db.query('DELETE FROM book_copies WHERE copy_id = ?', [ids.copy]);
    await db.query('DELETE FROM bibliographic_records WHERE bib_id = ?', [ids.bib]);
    await db.query('DELETE FROM readers WHERE reader_id = ?', [ids.reader]);
    await db.query('DELETE FROM users WHERE user_id = ?', [ids.user]);
    await db.end();
});

test('xóa sách có lịch sử sẽ ẩn khỏi danh mục nhưng không mất giao dịch', async () => {
    const result = await booksService.deleteBook(ids.bib);
    assert.equal(result.deletion_mode, 'archived');

    const [books] = await db.query(
        'SELECT archived_at FROM bibliographic_records WHERE bib_id = ?',
        [ids.bib]
    );
    assert.ok(books[0].archived_at);

    const [copies] = await db.query(
        'SELECT status FROM book_copies WHERE copy_id = ?',
        [ids.copy]
    );
    assert.equal(copies[0].status, 'processing');

    const [transactions] = await db.query(
        'SELECT tx_id FROM borrow_transactions WHERE tx_id = ?',
        [ids.transaction]
    );
    assert.equal(transactions.length, 1);

    const visible = await booksService.searchBooks({
        keyword: `E2E Archived Book ${suffix}`,
        page: 1,
        limit: 20
    });
    assert.equal(visible.total, 0);
    assert.deepEqual(visible.items, []);
});
