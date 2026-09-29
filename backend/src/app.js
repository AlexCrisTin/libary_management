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
const notificationsRoutes = require('./modules/notifications/notifications.routes');
const chatRoutes = require('./modules/chat/chat.routes');
const uploadsRoutes = require('./modules/uploads/uploads.routes');
const categoriesRoutes = require('./modules/categories/categories.routes');
const publishersRoutes = require('./modules/publishers/publishers.routes');
const dashboardRoutes = require('./modules/dashboard/dashboard.routes');

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
app.use('/api/dashboard', dashboardRoutes);

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
    } catch (error) {
        res.status(503).json({
            status: 'ERROR',
            timestamp: new Date().toISOString(),
            services: {
                server: 'healthy',
                database: 'disconnected'
            },
            error: error.message
        });
    }
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
