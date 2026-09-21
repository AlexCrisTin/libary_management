const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
    host: process.env.DB_HOST || '127.0.0.1',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'library_auth_db',
    port: process.env.DB_PORT || 3306,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    timezone: '+07:00'
});

pool.getConnection()
    .then((conn) => {
        console.log('[Auth Service Database] Ket noi MySQL (library_auth_db) thanh cong!');
        conn.release();
    })
    .catch((err) => {
        console.error('[Auth Service Database] Loi ket noi MySQL:', err.message);
    });

module.exports = pool;
