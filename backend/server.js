require('dotenv').config();
const app = require('./src/app');
const { startOverdueScheduler } = require('./src/jobs/overdueNotification.job');

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`[Server] Server đang chạy tại: http://localhost:${PORT}`);
    console.log(`[Books API] Sẵn sàng tại: http://localhost:${PORT}/api/books`);
    
    // Khoi dong tien trinh tu dong quet sach qua han (Dinh ky 60 phut)
    startOverdueScheduler(60);
});
