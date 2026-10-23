const test = require('node:test');
const assert = require('node:assert/strict');

const dbPath = require.resolve('../src/config/db');
const calls = [];
const fakeDb = {
    query: async (sql) => {
        calls.push(sql);
        if (sql.includes('COUNT(*) AS total')) return [[{ total: 1 }], []];
        if (sql.includes('latest.message_id AS last_message_id')) {
            return [[{
                reader_id: 'reader-1',
                reader_name: 'Trần Ngọc An',
                last_message_id: 'message-2',
                last_message: 'Tin nhắn mới nhất',
                unread_count: 0
            }], []];
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

const chatService = require('../src/modules/chat/chat.service');

test('mỗi độc giả chỉ xuất hiện một lần với tin nhắn mới nhất', async () => {
    const result = await chatService.getConversations({ page: 1, limit: 20 });

    assert.equal(result.total, 1);
    assert.equal(result.data.length, 1);
    assert.equal(result.data[0].last_message_id, 'message-2');

    const countQuery = calls.find((sql) => sql.includes('COUNT(*) AS total'));
    assert.match(countQuery, /r\.archived_at IS NULL/);
    assert.match(countQuery, /EXISTS/);

    const conversationsQuery = calls.find((sql) =>
        sql.includes('latest.message_id AS last_message_id')
    );
    assert.match(conversationsQuery, /latest\.message_id =/);
    assert.match(
        conversationsQuery,
        /ORDER BY cm\.created_at DESC, cm\.message_id DESC/
    );
    assert.match(conversationsQuery, /r\.archived_at IS NULL/);
});
