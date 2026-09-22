const db = require('../../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_library_jwt_key_2024';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

/**
 * 1. Đăng ký tài khoản Độc giả (Tạo user và hồ sơ reader)
 */
exports.register = async ({ username, password, full_name, email, phone, reader_type = 'student', faculty = null, birth_date = null }) => {
    // Kiểm tra username đã tồn tại chưa
    const [existingUsers] = await db.query('SELECT user_id FROM users WHERE username = ?', [username]);
    if (existingUsers.length > 0) {
        throw new Error('Tên đăng nhập này đã được sử dụng!');
    }

    // Kiểm tra email nếu có
    if (email) {
        const [existingEmail] = await db.query('SELECT reader_id FROM readers WHERE email = ?', [email]);
        if (existingEmail.length > 0) {
            throw new Error('Email này đã được sử dụng!');
        }
    }

    // Băm mật khẩu
    const passwordHash = await bcrypt.hash(password, 10);
    const userId = uuidv4();
    const readerId = uuidv4();
    const readerCode = `RD-${Date.now().toString().slice(-6)}`;

    // Tạo tài khoản trong bảng users (role: reader)
    await db.query(
        'INSERT INTO users (user_id, username, password_hash, role, is_active) VALUES (?, ?, ?, "reader", 1)',
        [userId, username, passwordHash]
    );

    // Tạo hồ sơ độc giả trong bảng readers (Thẻ có hạn 1 năm tính từ ngày đăng ký)
    const cardIssued = new Date();
    const cardExpired = new Date();
    cardExpired.setFullYear(cardExpired.getFullYear() + 1);

    await db.query(
        `INSERT INTO readers (
            reader_id, user_id, reader_code, full_name, birth_date, 
            phone, email, reader_type, faculty, card_issued, card_expired, 
            status, max_books
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, "active", 5)`,
        [readerId, userId, readerCode, full_name, birth_date, phone, email, reader_type, faculty, cardIssued, cardExpired]
    );

    // Tạo JWT Token
    const token = jwt.sign(
        { userId, username, role: 'reader', readerId, readerCode },
        JWT_SECRET,
        { expiresIn: JWT_EXPIRES_IN }
    );

    return {
        token,
        user: {
            user_id: userId,
            reader_id: readerId,
            reader_code: readerCode,
            username,
            full_name,
            role: 'reader',
            email
        }
    };
};

/**
 * 2. Đăng nhập (Áp dụng cho CẢ Thủ thư và Độc giả)
 */
exports.login = async ({ username, password }) => {
    // Tìm tài khoản theo username
    const [users] = await db.query('SELECT * FROM users WHERE username = ?', [username]);
    if (users.length === 0) {
        throw new Error('Tài khoản hoặc mật khẩu không chính xác!');
    }

    const user = users[0];

    // Kiểm tra tài khoản có bị khóa không
    if (!user.is_active) {
        throw new Error('Tài khoản này đã bị khóa! Vui lòng liên hệ quản trị viên.');
    }

    // So khớp mật khẩu băm
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
        throw new Error('Tài khoản hoặc mật khẩu không chính xác!');
    }

    let payload = {
        userId: user.user_id,
        username: user.username,
        role: user.role
    };

    let userResponse = {
        user_id: user.user_id,
        username: user.username,
        role: user.role
    };

    // Nếu là Độc giả -> Lấy thêm thông tin hồ sơ bên bảng readers
    if (user.role === 'reader') {
        const [readers] = await db.query('SELECT * FROM readers WHERE user_id = ?', [user.user_id]);
        if (readers.length > 0) {
            const reader = readers[0];
            payload.readerId = reader.reader_id;
            payload.readerCode = reader.reader_code;

            userResponse.reader_id = reader.reader_id;
            userResponse.reader_code = reader.reader_code;
            userResponse.full_name = reader.full_name;
            userResponse.email = reader.email;
            userResponse.card_status = reader.status;
            userResponse.card_expired = reader.card_expired;
        }
    }

    // Ký JWT Token
    const token = jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });

    return {
        token,
        user: userResponse
    };
};

/**
 * 3. Đổi mật khẩu
 */
exports.changePassword = async (userId, { oldPassword, newPassword }) => {
    const [users] = await db.query('SELECT password_hash FROM users WHERE user_id = ?', [userId]);
    if (users.length === 0) {
        throw new Error('Không tìm thấy tài khoản!');
    }

    const isMatch = await bcrypt.compare(oldPassword, users[0].password_hash);
    if (!isMatch) {
        throw new Error('Mật khẩu hiện tại không chính xác!');
    }

    const newHash = await bcrypt.hash(newPassword, 10);
    await db.query('UPDATE users SET password_hash = ? WHERE user_id = ?', [newHash, userId]);

    return true;
};
