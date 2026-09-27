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
        'INSERT INTO users (user_id, username, email, password_hash, role, is_active) VALUES (?, ?, ?, ?, "reader", 1)',
        [userId, username, email ? email.trim().toLowerCase() : null, passwordHash]
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

    // Tạo cấu hình sở thích mặc định trong bảng reader_preferences
    await db.query(
        `INSERT INTO reader_preferences (reader_id, preferred_subjects, preferred_authors, preferred_langs, reading_pace, notification_pref)
         VALUES (?, '[]', '[]', '["vi"]', 'medium', '{"email": true, "app": true, "sms": false}')`,
        [readerId]
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

/**
 * 4. Yêu cầu mã OTP đặt lại mật khẩu (Forgot Password)
 */
exports.forgotPassword = async ({ email }) => {
    if (!email || !email.trim()) {
        throw new Error('Vui lòng nhập địa chỉ email!');
    }

    const cleanEmail = email.trim().toLowerCase();

    // Tìm tài khoản liên kết với email này (hỗ trợ cả email ở bảng users hoặc bảng readers)
    const [users] = await db.query(
        `SELECT u.user_id, u.username, u.role, COALESCE(u.email, r.email) AS user_email
         FROM users u
         LEFT JOIN readers r ON u.user_id = r.user_id
         WHERE u.email = ? OR r.email = ?
         LIMIT 1`,
        [cleanEmail, cleanEmail]
    );

    if (users.length === 0) {
        throw new Error('Không tìm thấy tài khoản nào liên kết với email này!');
    }

    const user = users[0];

    // Sinh mã OTP ngẫu nhiên 6 chữ số
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Hạn sử dụng: 5 phút tính từ thời điểm hiện tại
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    // Lưu mã OTP vào bảng password_resets (Nếu đã có yêu cầu trước đó thì ghi đè mã mới)
    await db.query(
        `INSERT INTO password_resets (email, otp, expires_at, created_at)
         VALUES (?, ?, ?, NOW())
         ON DUPLICATE KEY UPDATE
             otp = VALUES(otp),
             expires_at = VALUES(expires_at),
             created_at = NOW()`,
        [cleanEmail, otp, expiresAt]
    );

    // In thông tin OTP ra Terminal để dễ dàng kiểm thử
    console.log('==================================================');
    console.log('[TEST MODE - MÃ XÁC THỰC OTP]');
    console.log(`Tài khoản: ${user.username} (${user.role})`);
    console.log(`Email nhận: ${cleanEmail}`);
    console.log(`MÃ OTP: ${otp}`);
    console.log(`Thời hạn: 5 phút (hết hạn lúc ${expiresAt.toLocaleTimeString('vi-VN')})`);
    console.log('==================================================');

    return {
        email: cleanEmail,
        username: user.username,
        role: user.role,
        dev_otp: otp,
        expires_in: '5 phút'
    };
};

/**
 * 5. Đặt lại mật khẩu mới bằng mã OTP (Reset Password)
 * Sau khi đặt thành công, mã OTP tự động bị xóa khỏi database
 */
exports.resetPassword = async ({ email, otp, new_password }) => {
    if (!email || !email.trim()) {
        throw new Error('Vui lòng nhập địa chỉ email!');
    }
    if (!otp) {
        throw new Error('Vui lòng nhập mã xác thực OTP!');
    }
    if (!new_password || new_password.trim().length < 6) {
        throw new Error('Mật khẩu mới phải có tối thiểu 6 ký tự!');
    }

    const cleanEmail = email.trim().toLowerCase();
    const cleanOtp = otp.toString().trim();

    // 1. Kiểm tra mã OTP trong bảng password_resets
    const [resets] = await db.query('SELECT * FROM password_resets WHERE email = ?', [cleanEmail]);
    if (resets.length === 0) {
        throw new Error('Không tìm thấy yêu cầu đặt lại mật khẩu cho email này! Vui lòng yêu cầu mã OTP mới.');
    }

    const resetRecord = resets[0];

    // Kiểm tra mã OTP có khớp không
    if (resetRecord.otp !== cleanOtp) {
        throw new Error('Mã OTP không chính xác!');
    }

    // Kiểm tra thời hạn mã OTP
    const now = new Date();
    if (now > new Date(resetRecord.expires_at)) {
        // Tự động xóa mã hết hạn khỏi database
        await db.query('DELETE FROM password_resets WHERE email = ?', [cleanEmail]);
        throw new Error('Mã OTP đã hết hạn sử dụng (quá 5 phút)! Vui lòng yêu cầu mã mới.');
    }

    // 2. Tìm tài khoản cần đổi mật khẩu
    const [users] = await db.query(
        `SELECT u.user_id, u.username
         FROM users u
         LEFT JOIN readers r ON u.user_id = r.user_id
         WHERE u.email = ? OR r.email = ?
         LIMIT 1`,
        [cleanEmail, cleanEmail]
    );

    if (users.length === 0) {
        throw new Error('Không tìm thấy tài khoản người dùng!');
    }

    const user = users[0];

    // 3. Băm mật khẩu mới và cập nhật vào bảng users
    const newPasswordHash = await bcrypt.hash(new_password.trim(), 10);
    await db.query('UPDATE users SET password_hash = ? WHERE user_id = ?', [newPasswordHash, user.user_id]);

    // 4. TỰ ĐỘNG XÓA MÃ OTP KHỎI DATABASE SAU KHI ĐÃ SỬ DỤNG THÀNH CÔNG
    await db.query('DELETE FROM password_resets WHERE email = ?', [cleanEmail]);

    return {
        username: user.username,
        message: 'Đặt lại mật khẩu thành công! Bạn có thể đăng nhập bằng mật khẩu mới.'
    };
};

/**
 * 6. Đăng xuất (Đưa token hiện tại vào blacklist để vô hiệu hóa ngay lập tức)
 */
exports.logout = async ({ token, user }) => {
    if (!token) {
        throw new Error('Không tìm thấy token để đăng xuất!');
    }

    // Lấy thời điểm hết hạn từ token (hoặc mặc định 7 ngày)
    let expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    if (user && user.exp) {
        expiresAt = new Date(user.exp * 1000);
    }

    const userId = user?.userId || null;

    // Lưu vào bảng token_blacklist
    await db.query(
        `INSERT INTO token_blacklist (token, user_id, expires_at, created_at)
         VALUES (?, ?, ?, NOW())`,
        [token, userId, expiresAt]
    );

    return {
        message: 'Đăng xuất thành công! Phiên đăng nhập đã được hủy bỏ.'
    };
};

// Tự động dọn dẹp các mã OTP đã quá hạn mỗi 10 phút
setInterval(async () => {
    try {
        await db.query('DELETE FROM password_resets WHERE expires_at < NOW()');
    } catch {
        // Bỏ qua lỗi nếu database chưa sẵn sàng
    }
}, 10 * 60 * 1000);

// Tự động dọn dẹp các token đã hết hạn trong blacklist mỗi 12 giờ
setInterval(async () => {
    try {
        await db.query('DELETE FROM token_blacklist WHERE expires_at < NOW()');
    } catch {
        // Bỏ qua lỗi nếu database chưa sẵn sàng
    }
}, 12 * 60 * 60 * 1000);

