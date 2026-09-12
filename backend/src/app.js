const express = require('express');
const cors = require('cors');

// Import routes
const booksRoutes = require('./modules/books/books.routes');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Đăng ký API Routes
app.use('/api/books', booksRoutes);

// Route kiểm tra sức khỏe server
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'OK', message: 'Library Backend Server đang chạy bình thường!' });
});

// Xử lý route không tồn tại (404)
app.use((req, res) => {
    res.status(404).json({ success: false, message: 'Đường dẫn API không tồn tại!' });
});

// Middleware xử lý lỗi toàn cục (Global Error Handler)
app.use((err, req, res, next) => {
    console.error('[Server Error]:', err.stack || err.message);
    res.status(500).json({
        success: false,
        message: 'Lỗi máy chủ nội bộ!',
        error: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});

module.exports = app;
