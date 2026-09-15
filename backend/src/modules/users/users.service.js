const db = require('../../config/db');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

/**
 * 1. Lấy danh sách toàn bộ tài khoản (Admin)
 */
exports.getAllUsers = async ({ role, is_active, keyword, page = 1, limit = 10 }) => {
    const offset = (page - 1) * limit;
    const params = [];
    const where = [];

    if (role) {
        where.push('u.role = ?');
        params.push(role);
    }

    if (is_active !== undefined) {
        where.push('u.is_active = ?');
        params.push(Number(is_active));
    }

    if (keyword && keyword.trim()) {
        where.push('(u.username LIKE ? OR r.full_name LIKE ? OR r.email LIKE ?)');
        const kw = `%${keyword.trim()}%`;
        params.push(kw, kw, kw);
    }

    const whereClause = where.length > 0 ? `WHERE ${where.join(' AND ')}` : '';

    const countSql = `
        SELECT COUNT(*) AS total 
        FROM users u 
        LEFT JOIN readers r ON u.user_id = r.user_id 
        ${whereClause}
    `;
    const [countRows] = await db.query(countSql, params);
    const total = countRows[0].total;

    const sql = `
        SELECT 
            u.user_id,
            u.username,
            u.role,
            u.is_active,
            u.created_at,
            r.reader_id,
            r.reader_code,
            r.full_name,
            r.email,
            r.phone
        FROM users u
        LEFT JOIN readers r ON u.user_id = r.user_id
        ${whereClause}
        ORDER BY u.created_at DESC
        LIMIT ? OFFSET ?
    `;
    const [rows] = await db.query(sql, [...params, Number(limit), Number(offset)]);

    return {
        total,
        page: Number(page),
        limit: Number(limit),
        totalPages: Math.ceil(total / limit),
        items: rows
    };
};

/**
 * 2. Lấy chi tiết một tài khoản
 */
exports.getUserById = async (userId) => {
    const sql = `
        SELECT 
            u.user_id,
            u.username,
            u.role,
            u.is_active,
            u.created_at,
            r.reader_id,
            r.reader_code,
            r.full_name,
            r.email,
            r.phone,
            r.status AS reader_status
        FROM users u
        LEFT JOIN readers r ON u.user_id = r.user_id
        WHERE u.user_id = ?
    `;
    const [rows] = await db.query(sql, [userId]);
    return rows[0] || null;
};

/**
 * 3. Tạo tài khoản mới (Admin tạo Thủ thư / Admin khác)
 */
exports.createUser = async ({ username, password, role = 'librarian', is_active = 1 }) => {
    const [existing] = await db.query('SELECT user_id FROM users WHERE username = ?', [username]);
    if (existing.length > 0) {
        throw new Error('Tên đăng nhập này đã tồn tại!');
    }

    const userId = uuidv4();
    const passwordHash = await bcrypt.hash(password, 10);

    const sql = 'INSERT INTO users (user_id, username, password_hash, role, is_active) VALUES (?, ?, ?, ?, ?)';
    await db.query(sql, [userId, username, passwordHash, role, is_active ? 1 : 0]);

    return {
        user_id: userId,
        username,
        role,
        is_active: Boolean(is_active)
    };
};

/**
 * 4. Đổi vai trò tài khoản (Phân quyền)
 */
exports.updateRole = async (userId, newRole) => {
    if (!['admin', 'librarian', 'reader'].includes(newRole)) {
        throw new Error('Vai trò không hợp lệ! Chỉ chấp nhận admin, librarian hoặc reader.');
    }
    const [result] = await db.query('UPDATE users SET role = ? WHERE user_id = ?', [newRole, userId]);
    return result.affectedRows > 0;
};

/**
 * 5. Khóa hoặc Mở khóa tài khoản
 */
exports.updateStatus = async (userId, isActive) => {
    const statusVal = isActive ? 1 : 0;
    const [result] = await db.query('UPDATE users SET is_active = ? WHERE user_id = ?', [statusVal, userId]);
    return result.affectedRows > 0;
};

/**
 * 6. Đặt lại mật khẩu (Admin reset password cho user)
 */
exports.resetPassword = async (userId, newPassword) => {
    const passwordHash = await bcrypt.hash(newPassword, 10);
    const [result] = await db.query('UPDATE users SET password_hash = ? WHERE user_id = ?', [passwordHash, userId]);
    return result.affectedRows > 0;
};

/**
 * 7. Xóa tài khoản
 */
exports.deleteUser = async (userId) => {
    const [result] = await db.query('DELETE FROM users WHERE user_id = ?', [userId]);
    return result.affectedRows > 0;
};
