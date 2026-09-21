const db = require('../../config/db');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

/**
 * 1. Lay danh sach nguoi dung (phan trang, tim kiem, loc)
 */
exports.getAllUsers = async ({ keyword = '', role = '', is_active = '', page = 1, limit = 10 }) => {
    const offset = (page - 1) * limit;
    const params = [];
    const where = [];

    if (keyword.trim()) {
        where.push('username LIKE ?');
        params.push(`%${keyword.trim()}%`);
    }

    if (role.trim()) {
        where.push('role = ?');
        params.push(role.trim());
    }

    if (is_active !== '') {
        where.push('is_active = ?');
        params.push(parseInt(is_active, 10));
    }

    const whereClause = where.length > 0 ? `WHERE ${where.join(' AND ')}` : '';

    const countSql = `SELECT COUNT(*) AS total FROM users ${whereClause}`;
    const [countRows] = await db.query(countSql, params);
    const total = countRows[0].total;

    const sql = `
        SELECT user_id, username, role, is_active, created_at 
        FROM users 
        ${whereClause} 
        ORDER BY created_at DESC 
        LIMIT ? OFFSET ?
    `;
    const [rows] = await db.query(sql, [...params, Number(limit), Number(offset)]);

    return {
        total,
        page,
        limit,
        total_pages: Math.ceil(total / limit),
        data: rows
    };
};

/**
 * 2. Lay chi tiet 1 nguoi dung theo user_id
 */
exports.getUserById = async (userId) => {
    const [users] = await db.query(
        'SELECT user_id, username, role, is_active, created_at FROM users WHERE user_id = ?',
        [userId]
    );

    if (users.length === 0) {
        return null;
    }

    return users[0];
};

/**
 * 3. Tao tai khoan Thu thu (role: librarian)
 */
exports.createLibrarian = async ({ username, password }) => {
    const [existing] = await db.query('SELECT user_id FROM users WHERE username = ?', [username]);
    if (existing.length > 0) {
        throw new Error('Ten dang nhap nay da duoc su dung!');
    }

    const userId = uuidv4();
    const passwordHash = await bcrypt.hash(password, 10);

    await db.query(
        'INSERT INTO users (user_id, username, password_hash, role, is_active) VALUES (?, ?, ?, "librarian", 1)',
        [userId, username, passwordHash]
    );

    return {
        user_id: userId,
        username,
        role: 'librarian'
    };
};

/**
 * 4. Khoa hoac mo khoa tai khoan
 */
exports.updateUserStatus = async (userId, isActive) => {
    const [users] = await db.query('SELECT role FROM users WHERE user_id = ?', [userId]);
    if (users.length === 0) {
        throw new Error('Khong tim thay nguoi dung!');
    }

    if (users[0].role === 'admin') {
        throw new Error('Khong the khoa tai khoan Admin toi cao!');
    }

    await db.query('UPDATE users SET is_active = ? WHERE user_id = ?', [isActive ? 1 : 0, userId]);

    return {
        user_id: userId,
        is_active: isActive ? 1 : 0,
        message: isActive ? 'Mo khoa tai khoan thanh cong' : 'Khoa tai khoan thanh cong'
    };
};

/**
 * 5. Thay doi vai tro (role)
 */
exports.updateUserRole = async (userId, role) => {
    const allowedRoles = ['admin', 'librarian', 'reader'];
    if (!allowedRoles.includes(role)) {
        throw new Error('Vai tro khong hop le!');
    }

    const [users] = await db.query('SELECT user_id FROM users WHERE user_id = ?', [userId]);
    if (users.length === 0) {
        throw new Error('Khong tim thay nguoi dung!');
    }

    await db.query('UPDATE users SET role = ? WHERE user_id = ?', [role, userId]);

    return {
        user_id: userId,
        role,
        message: 'Cap nhat vai tro thanh cong'
    };
};

/**
 * 6. Dat lai mat khau (Reset password do Admin thuc hien)
 */
exports.resetPassword = async (userId, newPassword) => {
    const [users] = await db.query('SELECT user_id FROM users WHERE user_id = ?', [userId]);
    if (users.length === 0) {
        throw new Error('Khong tim thay nguoi dung!');
    }

    const hash = await bcrypt.hash(newPassword, 10);
    await db.query('UPDATE users SET password_hash = ? WHERE user_id = ?', [hash, userId]);

    return {
        user_id: userId,
        message: 'Dat lai mat khau thanh cong'
    };
};
