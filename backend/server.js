require('dotenv').config();
const app = require('./src/app');

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`[Server] Server đang chạy tại: http://localhost:${PORT}`);
    console.log(`[Books API] Sẵn sàng tại: http://localhost:${PORT}/api/books`);
});
