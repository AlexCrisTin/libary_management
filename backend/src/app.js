const express = require('express');
const cors = require('cors');
const path = require('path');

// Import routes
const authRoutes = require('./modules/auth/auth.routes');
const usersRoutes = require('./modules/users/users.routes');
const booksRoutes = require('./modules/books/books.routes');
const shelvesRoutes = require('./modules/shelves/shelves.routes');
const readersRoutes = require('./modules/readers/readers.routes');
const circulationRoutes = require('./modules/circulation/circulation.routes');
const holdsRoutes = require('./modules/holds/holds.routes');
const notificationsRoutes = require('./modules/notifications/notifications.routes');
const chatRoutes = require('./modules/chat/chat.routes');
const uploadsRoutes = require('./modules/uploads/uploads.routes');
const categoriesRoutes = require('./modules/categories/categories.routes');
const publishersRoutes = require('./modules/publishers/publishers.routes');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Dang ky cac API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/books', booksRoutes);
app.use('/api/shelves', shelvesRoutes);
app.use('/api/readers', readersRoutes);
app.use('/api/circulation', circulationRoutes);
app.use('/api/holds', holdsRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/uploads', uploadsRoutes);
app.use('/api/categories', categoriesRoutes);
app.use('/api/publishers', publishersRoutes);

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
        error: err.message || 'Unknown error'
    });
});

module.exports = app;
