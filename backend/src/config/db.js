const mysql = require('mysql2/promise');
require('dotenv').config();

// Tạo Connection Pool kết nối đến MySQL (XAMPP)
const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'library_db',
    port: process.env.DB_PORT || 3306,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    timezone: '+07:00'
});

// Kiểm tra kết nối khi khởi động
pool.getConnection()
    .then((conn) => {
        console.log('[Database] Kết nối MySQL (XAMPP) thành công!');
        conn.release();
    })
    .catch((err) => {
        console.error('[Database] Lỗi kết nối MySQL:', err.message);
    });

module.exports = pool;
