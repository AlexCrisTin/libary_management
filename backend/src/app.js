const express = require('express');
const cors = require('cors');

// Import routes
const authRoutes = require('./modules/auth/auth.routes');
const usersRoutes = require('./modules/users/users.routes');
const booksRoutes = require('./modules/books/books.routes');
const shelvesRoutes = require('./modules/shelves/shelves.routes');
const readersRoutes = require('./modules/readers/readers.routes');
const circulationRoutes = require('./modules/circulation/circulation.routes');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Dang ky cac API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/books', booksRoutes);
app.use('/api/shelves', shelvesRoutes);
app.use('/api/readers', readersRoutes);
app.use('/api/circulation', circulationRoutes);

// Route kiem tra suc khoe server
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'OK', message: 'Library Backend Server dang chay binh thuong!' });
});

// Xu ly route khong ton tai (404)
app.use((req, res) => {
    res.status(404).json({ success: false, message: 'Duong dan API khong ton tai!' });
});

// Middleware xu ly loi toan cuc (Global Error Handler)
app.use((err, req, res, next) => {
    console.error('[Server Error]:', err.stack || err.message);
    res.status(500).json({
        success: false,
        message: 'Loi may chu noi bo!',
        error: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});

module.exports = app;
