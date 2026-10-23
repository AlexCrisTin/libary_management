const path = require('path');
const { randomUUID } = require('crypto');
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const bcrypt = require('bcryptjs');

require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const db = require('../src/config/db');
const usersService = require('../src/modules/users/users.service');
const readersService = require('../src/modules/readers/readers.service');

const userId = randomUUID();
const readerId = randomUUID();
const suffix = randomUUID().replaceAll('-', '').slice(0, 10).toUpperCase();
const readerCode = `RD-${suffix}`;

before(async () => {
    const passwordHash = await bcrypt.hash('DeleteTest@123', 8);
    await db.query(
        `INSERT INTO users
         (user_id, username, full_name, password_hash, role, is_active)
         VALUES (?, ?, 'E2E Delete Reader', ?, 'reader', 1)`,
        [userId, `e2e_delete_${suffix}`, passwordHash]
    );
    await db.query(
        `INSERT INTO readers
         (reader_id, user_id, reader_code, full_name, reader_type,
          card_issued, card_expired, status, max_books)
         VALUES (?, ?, ?, 'E2E Delete Reader', 'student',
                 CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR), 'active', 5)`,
        [readerId, userId, readerCode]
    );
});

after(async () => {
    await db.query('DELETE FROM readers WHERE reader_id = ?', [readerId]);
    await db.query('DELETE FROM users WHERE user_id = ?', [userId]);
    await db.end();
});

test('xóa tài khoản ẩn hồ sơ độc giả nhưng vẫn giữ được bản ghi lịch sử', async () => {
    const deleted = await usersService.deleteUser(userId);
    assert.equal(deleted, true);

    const [users] = await db.query(
        'SELECT user_id FROM users WHERE user_id = ?',
        [userId]
    );
    assert.equal(users.length, 0);

    const [readers] = await db.query(
        `SELECT user_id, status, archived_at
         FROM readers WHERE reader_id = ?`,
        [readerId]
    );
    assert.equal(readers.length, 1);
    assert.equal(readers[0].user_id, null);
    assert.equal(readers[0].status, 'suspended');
    assert.ok(readers[0].archived_at);

    const visible = await readersService.getAllReaders({ keyword: readerCode });
    assert.equal(visible.total, 0);
    assert.deepEqual(visible.items, []);
});
