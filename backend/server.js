require('dotenv').config();
const app = require('./src/app');
const { startOverdueScheduler } = require('./src/jobs/overdueNotification.job');
const { startCardExpirationScheduler } = require('./src/jobs/cardExpirationNotification.job');

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

app.listen(PORT, HOST, () => {
    console.log(`[Server] Server đang chạy tại: http://${HOST}:${PORT}`);
    console.log(`[Books API] Sẵn sàng tại: http://${HOST}:${PORT}/api/books`);
    
    // Khoi dong tien trinh tu dong quet sach qua han (Dinh ky 60 phut)
    startOverdueScheduler(60);
    startCardExpirationScheduler(60);
});
