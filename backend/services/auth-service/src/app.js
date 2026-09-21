const express = require('express');
const cors = require('cors');

const authRoutes = require('./modules/auth/auth.routes');
const usersRoutes = require('./modules/users/users.routes');

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Dang ky API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', usersRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        service: 'auth-service',
        status: 'OK',
        message: 'Auth Microservice dang chay binh thuong!'
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Duong dan API khong ton tai tren Auth Service!'
    });
});

// Global error handler
app.use((err, req, res, next) => {
    console.error('[Auth Service Error]:', err.stack || err.message);
    res.status(500).json({
        success: false,
        message: 'Loi may chu noi bo tren Auth Service!',
        error: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});

module.exports = app;
