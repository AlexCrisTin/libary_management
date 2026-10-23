const db = require('../../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const {
    generateOtp,
    getJwtSecret,
    hashOtp,
    hashToken,
    passwordVersion,
    shouldExposeDevOtp,
    verifyOtp
} = require('../../config/security');

const JWT_SECRET = getJwtSecret();
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';
const MIN_PASSWORD_LENGTH = 8;

/**
 * 1. Đăng ký tài khoản Độc giả (Tạo user và hồ sơ reader)
 */
exports.register = async ({ username, password, full_name, email, phone, reader_type = 'student', faculty = null, birth_date = null }) => {
    const cleanUsername = String(username || '').trim();
    const cleanFullName = String(full_name || '').trim();
    const cleanEmail = email && String(email).trim()
        ? String(email).trim().toLowerCase()
        : null;
    if (!cleanUsername || !cleanFullName) {
        throw new Error('Tên đăng nhập và họ tên không được để trống!');
    }
    if (!password || String(password).length < MIN_PASSWORD_LENGTH) {
        throw new Error(`Mật khẩu phải có tối thiểu ${MIN_PASSWORD_LENGTH} ký tự!`);
    }
    if (!['student', 'lecturer', 'staff', 'public'].includes(reader_type)) {
        throw new Error('Loại độc giả không hợp lệ!');
    }

    // Băm mật khẩu
    const passwordHash = await bcrypt.hash(password, 10);
    const userId = uuidv4();
    const readerId = uuidv4();
    const readerCode = `RD-${uuidv4().replaceAll('-', '').slice(0, 10).toUpperCase()}`;

    // Tạo hồ sơ độc giả trong bảng readers (Thẻ có hạn 1 năm tính từ ngày đăng ký)
    const cardIssued = new Date();
    const cardExpired = new Date();
    cardExpired.setFullYear(cardExpired.getFullYear() + 1);

    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();
        const [existingUsers] = await connection.query(
            'SELECT user_id FROM users WHERE username = ? LIMIT 1',
            [cleanUsername]
        );
        if (existingUsers.length > 0) {
            throw new Error('Tên đăng nhập này đã được sử dụng!');
        }
        if (cleanEmail) {
            const [existingEmail] = await connection.query(
                `SELECT u.user_id
                 FROM users u
                 LEFT JOIN readers r ON r.user_id = u.user_id
                 WHERE u.email = ? OR r.email = ?
                 LIMIT 1`,
                [cleanEmail, cleanEmail]
            );
            if (existingEmail.length > 0) {
                throw new Error('Email này đã được sử dụng!');
            }
        }

        await connection.query(
            'INSERT INTO users (user_id, username, email, full_name, phone, password_hash, role, is_active) VALUES (?, ?, ?, ?, ?, ?, "reader", 1)',
            [userId, cleanUsername, cleanEmail, cleanFullName, phone || null, passwordHash]
        );
        await connection.query(
            `INSERT INTO readers (
                reader_id, user_id, reader_code, full_name, birth_date,
                phone, email, reader_type, faculty, card_issued, card_expired,
                status, max_books
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, "active", 5)`,
            [readerId, userId, readerCode, cleanFullName, birth_date, phone, cleanEmail, reader_type, faculty, cardIssued, cardExpired]
        );
        await connection.query(
            `INSERT INTO reader_preferences
             (reader_id, preferred_subjects, preferred_authors, preferred_langs, reading_pace, notification_pref)
             VALUES (?, '[]', '[]', '["vi"]', 'medium', '{"email": true, "app": true, "sms": false}')`,
            [readerId]
        );
        await connection.commit();
    } catch (error) {
        await connection.rollback();
        throw error;
    } finally {
        connection.release();
    }

    // Tạo JWT Token
    const token = jwt.sign(
        {
            userId,
            username: cleanUsername,
            role: 'reader',
            readerId,
            readerCode,
            passwordVersion: passwordVersion(passwordHash)
        },
        JWT_SECRET,
        { expiresIn: JWT_EXPIRES_IN }
    );

    return {
        token,
        user: {
            user_id: userId,
            reader_id: readerId,
            reader_code: readerCode,
            username: cleanUsername,
            full_name: cleanFullName,
            phone,
            role: 'reader',
            email: cleanEmail
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
        role: user.role,
        passwordVersion: passwordVersion(user.password_hash)
    };

    let userResponse = {
        user_id: user.user_id,
        username: user.username,
        email: user.email,
        full_name: user.full_name,
        phone: user.phone,
        avatar_url: user.avatar_url,
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
            userResponse.full_name = reader.full_name || user.full_name;
            userResponse.email = reader.email || user.email;
            userResponse.phone = reader.phone || user.phone;
            userResponse.avatar_url = reader.avatar_url || user.avatar_url;
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
    if (!newPassword || String(newPassword).length < MIN_PASSWORD_LENGTH) {
        throw new Error(`Mật khẩu mới phải có tối thiểu ${MIN_PASSWORD_LENGTH} ký tự!`);
    }
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
 * 4. Lấy chi tiết thông tin tài khoản hiện tại từ Database
 */
exports.getMe = async (userId) => {
    const [users] = await db.query(
        `SELECT user_id, username, email, full_name, phone, avatar_url, role, is_active, created_at 
         FROM users WHERE user_id = ?`,
        [userId]
    );
    if (users.length === 0) {
        throw new Error('Không tìm thấy tài khoản người dùng!');
    }

    const user = users[0];

    // Nếu là Độc giả -> Lấy kèm thông tin thẻ thư viện bên bảng readers
    if (user.role === 'reader') {
        const [readers] = await db.query('SELECT * FROM readers WHERE user_id = ?', [userId]);
        if (readers.length > 0) {
            const r = readers[0];
            return {
                ...user,
                reader_id: r.reader_id,
                reader_code: r.reader_code,
                full_name: r.full_name || user.full_name,
                phone: r.phone || user.phone,
                email: r.email || user.email,
                avatar_url: r.avatar_url || user.avatar_url,
                birth_date: r.birth_date,
                reader_type: r.reader_type,
                faculty: r.faculty,
                card_issued: r.card_issued,
                card_expired: r.card_expired,
                card_status: r.status,
                max_books: r.max_books
            };
        }
    }

    return user;
};

/**
 * 5. Cập nhật hồ sơ cá nhân (Dành cho CẢ Thủ thư, Admin và Độc giả)
 */
exports.updateProfile = async (userId, { full_name, phone, email, avatar_url }) => {
    const [users] = await db.query('SELECT * FROM users WHERE user_id = ?', [userId]);
    if (users.length === 0) {
        throw new Error('Không tìm thấy tài khoản người dùng!');
    }
    const user = users[0];

    // Nếu có cập nhật email -> Kiểm tra trùng lặp
    let cleanEmail = user.email;
    if (email !== undefined) {
        cleanEmail = email && email.trim() ? email.trim().toLowerCase() : null;
        if (cleanEmail && cleanEmail !== user.email) {
            const [existing] = await db.query(
                `SELECT u.user_id
                 FROM users u
                 LEFT JOIN readers r ON r.user_id = u.user_id
                 WHERE (u.email = ? OR r.email = ?) AND u.user_id != ?
                 UNION ALL
                 SELECT CONCAT('reader:', r2.reader_id) AS user_id
                 FROM readers r2
                 WHERE r2.email = ? AND r2.user_id IS NULL
                 LIMIT 1`,
                [cleanEmail, cleanEmail, userId, cleanEmail]
            );
            if (existing.length > 0) {
                throw new Error('Email này đã được sử dụng bởi một tài khoản khác!');
            }
        }
    }

    const newFullName = full_name !== undefined ? (full_name ? full_name.trim() : null) : user.full_name;
    const newPhone = phone !== undefined ? (phone ? phone.trim() : null) : user.phone;
    const newAvatarUrl = avatar_url !== undefined ? avatar_url : user.avatar_url;

    // 1. Cập nhật vào bảng users
    await db.query(
        `UPDATE users 
         SET full_name = ?, phone = ?, email = ?, avatar_url = ? 
         WHERE user_id = ?`,
        [newFullName, newPhone, cleanEmail, newAvatarUrl, userId]
    );

    // 2. Nếu là Độc giả -> Đồng bộ sang cả bảng readers
    if (user.role === 'reader') {
        await db.query(
            `UPDATE readers 
             SET full_name = COALESCE(?, full_name), 
                 phone = COALESCE(?, phone), 
                 email = COALESCE(?, email), 
                 avatar_url = COALESCE(?, avatar_url) 
             WHERE user_id = ?`,
            [newFullName, newPhone, cleanEmail, newAvatarUrl, userId]
        );
    }

    return exports.getMe(userId);
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
        `SELECT DISTINCT u.user_id
         FROM users u
         LEFT JOIN readers r ON u.user_id = r.user_id
         WHERE u.email = ? OR r.email = ?
         LIMIT 2`,
        [cleanEmail, cleanEmail]
    );

    // Cùng một phản hồi cho email không tồn tại hoặc email bị trùng để tránh lộ tài khoản.
    if (users.length !== 1) {
        return { email: cleanEmail, expires_in: '5 phút' };
    }

    // Sinh mã OTP bằng bộ sinh số mật mã và chỉ lưu bản băm.
    const otp = generateOtp();

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
        [cleanEmail, hashOtp(cleanEmail, otp), expiresAt]
    );

    const response = {
        email: cleanEmail,
        expires_in: '5 phút'
    };
    if (shouldExposeDevOtp()) response.dev_otp = otp;
    return response;
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
    if (!new_password || new_password.trim().length < MIN_PASSWORD_LENGTH) {
        throw new Error(`Mật khẩu mới phải có tối thiểu ${MIN_PASSWORD_LENGTH} ký tự!`);
    }

    const cleanEmail = email.trim().toLowerCase();
    const cleanOtp = otp.toString().trim();

    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();
        // Khóa bản ghi để cùng một OTP không thể được dùng thành công hai lần đồng thời.
        const [resets] = await connection.query(
            'SELECT * FROM password_resets WHERE email = ? FOR UPDATE',
            [cleanEmail]
        );
        if (resets.length === 0) {
            throw new Error('Không tìm thấy yêu cầu đặt lại mật khẩu cho email này! Vui lòng yêu cầu mã OTP mới.');
        }

        const resetRecord = resets[0];
        if (!verifyOtp(cleanEmail, cleanOtp, resetRecord.otp)) {
            throw new Error('Mã OTP không chính xác!');
        }
        if (new Date() > new Date(resetRecord.expires_at)) {
            throw new Error('Mã OTP đã hết hạn sử dụng (quá 5 phút)! Vui lòng yêu cầu mã mới.');
        }

        const [users] = await connection.query(
            `SELECT DISTINCT u.user_id, u.username
             FROM users u
             LEFT JOIN readers r ON u.user_id = r.user_id
             WHERE u.email = ? OR r.email = ?
             LIMIT 2`,
            [cleanEmail, cleanEmail]
        );
        if (users.length !== 1) {
            throw new Error('Không thể xác định duy nhất tài khoản cho email này!');
        }
        const user = users[0];
        const newPasswordHash = await bcrypt.hash(new_password.trim(), 10);
        await connection.query(
            'UPDATE users SET password_hash = ? WHERE user_id = ?',
            [newPasswordHash, user.user_id]
        );
        await connection.query('DELETE FROM password_resets WHERE email = ?', [cleanEmail]);
        await connection.commit();

        return {
            username: user.username,
            message: 'Đặt lại mật khẩu thành công! Bạn có thể đăng nhập bằng mật khẩu mới.'
        };
    } catch (error) {
        await connection.rollback();
        throw error;
    } finally {
        connection.release();
    }
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
        [hashToken(token), userId, expiresAt]
    );

    return {
        message: 'Đăng xuất thành công! Phiên đăng nhập đã được hủy bỏ.'
    };
};

// Tự động dọn dẹp các mã OTP đã quá hạn mỗi 10 phút
const otpCleanupTimer = setInterval(async () => {
    try {
        await db.query('DELETE FROM password_resets WHERE expires_at < NOW()');
    } catch {
        // Bỏ qua lỗi nếu database chưa sẵn sàng
    }
}, 10 * 60 * 1000);
otpCleanupTimer.unref();

// Tự động dọn dẹp các token đã hết hạn trong blacklist mỗi 12 giờ
const tokenCleanupTimer = setInterval(async () => {
    try {
        await db.query('DELETE FROM token_blacklist WHERE expires_at < NOW()');
    } catch {
        // Bỏ qua lỗi nếu database chưa sẵn sàng
    }
}, 12 * 60 * 60 * 1000);
tokenCleanupTimer.unref();

