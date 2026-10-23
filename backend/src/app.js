const express = require('express');
const cors = require('cors');
const path = require('path');
const db = require('./config/db');
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./docs/swagger.json');

// Import routes
const authRoutes = require('./modules/auth/auth.routes');
const usersRoutes = require('./modules/users/users.routes');
const booksRoutes = require('./modules/books/books.routes');
const shelvesRoutes = require('./modules/shelves/shelves.routes');
const readersRoutes = require('./modules/readers/readers.routes');
const circulationRoutes = require('./modules/circulation/circulation.routes');
const holdsRoutes = require('./modules/holds/holds.routes');
const pickupReservationsRoutes = require('./modules/pickupReservations/pickupReservations.routes');
const notificationsRoutes = require('./modules/notifications/notifications.routes');
const chatRoutes = require('./modules/chat/chat.routes');
const uploadsRoutes = require('./modules/uploads/uploads.routes');
const categoriesRoutes = require('./modules/categories/categories.routes');
const publishersRoutes = require('./modules/publishers/publishers.routes');
const dashboardRoutes = require('./modules/dashboard/dashboard.routes');
const aiRoutes = require('./modules/ai/ai.routes');
const { apiLimiter } = require('./middlewares/rateLimiter.middleware');

const app = express();

// Middleware
app.disable('x-powered-by');

const configuredOrigins = String(process.env.CORS_ORIGINS || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
const localDevelopmentOrigin = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i;
app.use(cors({
    origin: (origin, callback) => {
        if (!origin || configuredOrigins.includes(origin)) return callback(null, true);
        if (process.env.NODE_ENV !== 'production' && localDevelopmentOrigin.test(origin)) {
            return callback(null, true);
        }
        return callback(new Error('Nguồn truy cập không được phép bởi CORS.'));
    },
    methods: ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    maxAge: 86400
}));
app.use((_req, res, next) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('Referrer-Policy', 'no-referrer');
    res.setHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
    next();
});
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));
app.use('/api', apiLimiter);

// Dang ky cac API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/books', booksRoutes);
app.use('/api/shelves', shelvesRoutes);
app.use('/api/readers', readersRoutes);
app.use('/api/circulation', circulationRoutes);
app.use('/api/holds', holdsRoutes);
app.use('/api/pickup-reservations', pickupReservationsRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/uploads', uploadsRoutes);
app.use('/api/categories', categoriesRoutes);
app.use('/api/publishers', publishersRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/ai', aiRoutes);

// Giao dien tai lieu truc quan Swagger UI / OpenAPI
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

// Endpoint xuat dac ta OpenAPI dang JSON chuan
app.get('/api-docs.json', (req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.json(swaggerDocument);
});

// Route kiem tra suc khoe server va database
app.get('/health', async (req, res) => {
    try {
        await db.query('SELECT 1');
        res.status(200).json({
            status: 'OK',
            timestamp: new Date().toISOString(),
            services: {
                server: 'healthy',
                database: 'connected'
            }
        });
    } catch (_error) {
        res.status(503).json({
            status: 'ERROR',
            timestamp: new Date().toISOString(),
            services: {
                server: 'healthy',
                database: 'disconnected'
            }
        });
    }
});

// Xu ly route khong ton tai (404)
app.use((req, res) => {
    res.status(404).json({ success: false, message: 'Duong dan API khong ton tai!' });
});

// Middleware xu ly loi toan cuc (Global Error Handler)
app.use((err, req, res, next) => {
    if (err.message === 'Nguồn truy cập không được phép bởi CORS.') {
        return res.status(403).json({ success: false, message: err.message });
    }
    console.error('[Server Error]:', err.stack || err.message);
    res.status(500).json({
        success: false,
        message: 'Loi may chu noi bo!'
    });
});

module.exports = app;
