const db = require('../../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_jwt_auth_service_key_2026';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

/**
 * 1. Dang ky tai khoan nguoi dung moi (mac dinh role: reader)
 */
exports.register = async ({ username, password }) => {
    // Kiem tra username da ton tai chua
    const [existingUsers] = await db.query('SELECT user_id FROM users WHERE username = ?', [username]);
    if (existingUsers.length > 0) {
        throw new Error('Ten dang nhap nay da ton tai trong he thong!');
    }

    const userId = uuidv4();
    const passwordHash = await bcrypt.hash(password, 10);

    await db.query(
        'INSERT INTO users (user_id, username, password_hash, role, is_active) VALUES (?, ?, ?, "reader", 1)',
        [userId, username, passwordHash]
    );

    const token = jwt.sign(
        { userId, username, role: 'reader' },
        JWT_SECRET,
        { expiresIn: JWT_EXPIRES_IN }
    );

    return {
        user_id: userId,
        username,
        role: 'reader',
        token
    };
};

/**
 * 2. Dang nhap he thong
 */
exports.login = async ({ username, password }) => {
    const [users] = await db.query('SELECT * FROM users WHERE username = ?', [username]);
    if (users.length === 0) {
        throw new Error('Tai khoan hoac mat khau khong chinh xac!');
    }

    const user = users[0];

    if (!user.is_active) {
        throw new Error('Tai khoan nay da bi khoa! Vui long lien he quan tri vien.');
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
        throw new Error('Tai khoan hoac mat khau khong chinh xac!');
    }

    const payload = {
        userId: user.user_id,
        username: user.username,
        role: user.role
    };

    const token = jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });

    return {
        token,
        user: {
            user_id: user.user_id,
            username: user.username,
            role: user.role
        }
    };
};

/**
 * 3. Lay thong tin tai khoan hien tai
 */
exports.getMe = async (userId) => {
    const [users] = await db.query(
        'SELECT user_id, username, role, is_active, created_at FROM users WHERE user_id = ?',
        [userId]
    );

    if (users.length === 0) {
        throw new Error('Khong tim thay thong tin tai khoan!');
    }

    return users[0];
};

/**
 * 4. Doi mat khau
 */
exports.changePassword = async ({ userId, old_password, new_password }) => {
    const [users] = await db.query('SELECT * FROM users WHERE user_id = ?', [userId]);
    if (users.length === 0) {
        throw new Error('Nguoi dung khong ton tai!');
    }

    const user = users[0];

    const isMatch = await bcrypt.compare(old_password, user.password_hash);
    if (!isMatch) {
        throw new Error('Mat khau cu khong dung!');
    }

    const newHash = await bcrypt.hash(new_password, 10);
    await db.query('UPDATE users SET password_hash = ? WHERE user_id = ?', [newHash, userId]);

    return { message: 'Doi mat khau thanh cong' };
};
