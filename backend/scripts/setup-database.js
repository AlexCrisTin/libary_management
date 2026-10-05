const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const dotenv = require('dotenv');

const backendRoot = path.resolve(__dirname, '..');
dotenv.config({ path: path.join(backendRoot, '.env') });

const args = new Set(process.argv.slice(2));
const reset = args.has('--reset');
const confirmed = args.has('--yes');
const schemaOnly = args.has('--schema-only');
const seedOnly = args.has('--seed-only');

if (schemaOnly && seedOnly) {
    console.error('Không thể dùng đồng thời --schema-only và --seed-only.');
    process.exit(1);
}

if (reset && !confirmed) {
    console.error('db:reset sẽ xóa toàn bộ database hiện tại. Chạy lại với: npm run db:reset -- --yes');
    process.exit(1);
}

const database = process.env.DB_NAME || 'library_db';
if (!/^[A-Za-z0-9_]+$/.test(database)) {
    console.error('DB_NAME chỉ được chứa chữ, số và dấu gạch dưới.');
    process.exit(1);
}

const connectionOptions = {
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    multipleStatements: true,
    charset: 'utf8mb4'
};

const schemaPath = path.join(backendRoot, 'database', 'schema.sql');
const seedPath = path.join(backendRoot, 'database', 'seed.sql');
const expectedTables = [
    'users', 'readers', 'reader_preferences', 'publishers', 'categories',
    'shelf_locations', 'bibliographic_records', 'book_copies',
    'borrow_transactions', 'renewal_requests', 'holds', 'notifications',
    'chat_messages', 'password_resets', 'token_blacklist',
    'ai_conversations', 'ai_messages', 'ai_usage_logs'
];

const readSql = (filePath) => fs.readFileSync(filePath, 'utf8');

async function main() {
    let connection;
    try {
        connection = await mysql.createConnection(connectionOptions);

        if (reset) {
            await connection.query(`DROP DATABASE IF EXISTS \`${database}\``);
            console.log(`Đã xóa database ${database}.`);
        }

        await connection.query(
            `CREATE DATABASE IF NOT EXISTS \`${database}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
        );
        await connection.changeUser({ database });

        if (!seedOnly) {
            await connection.query(readSql(schemaPath));
            console.log('Đã cài đặt schema.');
        }

        if (!schemaOnly) {
            const [userCountRows] = await connection.query('SELECT COUNT(*) AS total FROM users');
            const hasExistingData = Number(userCountRows[0].total) > 0;

            if (hasExistingData && !seedOnly && !reset) {
                console.log('Database đã có dữ liệu nên bỏ qua seed demo để bảo toàn dữ liệu hiện tại.');
            } else {
                await connection.query(readSql(seedPath));
                console.log('Đã cài đặt dữ liệu demo.');
            }
        }

        const [tableRows] = await connection.query('SHOW TABLES');
        const installedTables = tableRows.map((row) => Object.values(row)[0]);
        const missingTables = expectedTables.filter((table) => !installedTables.includes(table));
        if (missingTables.length > 0) {
            throw new Error(`Thiếu bảng sau khi cài đặt: ${missingTables.join(', ')}`);
        }

        const [counts] = await connection.query(`
            SELECT
                (SELECT COUNT(*) FROM users) AS users,
                (SELECT COUNT(*) FROM readers) AS readers,
                (SELECT COUNT(*) FROM bibliographic_records) AS books,
                (SELECT COUNT(*) FROM book_copies) AS copies,
                (SELECT COUNT(*) FROM borrow_transactions) AS transactions
        `);

        console.log(`Database ${database} đã sẵn sàng với ${installedTables.length} bảng.`);
        console.log('Dữ liệu hiện có:', counts[0]);
    } catch (error) {
        console.error('Cài đặt database thất bại:', error.message);
        process.exitCode = 1;
    } finally {
        if (connection) await connection.end();
    }
}

main();
