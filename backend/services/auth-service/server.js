require('dotenv').config();
const app = require('./src/app');

const PORT = process.env.PORT || 3001;

app.listen(PORT, () => {
    console.log(`[Auth Service] Server dang chay tai: http://localhost:${PORT}`);
    console.log(`[Auth Service] Database ket noi: ${process.env.DB_NAME || 'library_auth_db'}`);
});
