const db = require('../../config/db');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

/**
 * 1. Lấy danh sách toàn bộ tài khoản (Admin)
 */
exports.getAllUsers = async ({ role, is_active, keyword, page = 1, limit = 10 }) => {
    const normalizedPage = Math.max(1, Number(page) || 1);
    const normalizedLimit = Math.min(100, Math.max(1, Number(limit) || 10));
    const offset = (normalizedPage - 1) * normalizedLimit;
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
        where.push('(u.username LIKE ? OR u.email LIKE ? OR r.full_name LIKE ? OR r.email LIKE ?)');
        const kw = `%${keyword.trim()}%`;
        params.push(kw, kw, kw, kw);
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
            COALESCE(u.email, r.email) AS email,
            COALESCE(u.full_name, r.full_name) AS full_name,
            COALESCE(u.phone, r.phone) AS phone,
            COALESCE(u.avatar_url, r.avatar_url) AS avatar_url,
            u.role,
            u.is_active,
            u.created_at,
            r.reader_id,
            r.reader_code
        FROM users u
        LEFT JOIN readers r ON u.user_id = r.user_id
        ${whereClause}
        ORDER BY u.created_at DESC
        LIMIT ? OFFSET ?
    `;
    const [rows] = await db.query(sql, [...params, normalizedLimit, offset]);

    return {
        total,
        page: normalizedPage,
        limit: normalizedLimit,
        totalPages: Math.ceil(total / normalizedLimit),
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
            COALESCE(u.email, r.email) AS email,
            COALESCE(u.full_name, r.full_name) AS full_name,
            COALESCE(u.phone, r.phone) AS phone,
            COALESCE(u.avatar_url, r.avatar_url) AS avatar_url,
            u.role,
            u.is_active,
            u.created_at,
            r.reader_id,
            r.reader_code,
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
exports.createUser = async ({ username, password, email, full_name, phone, role = 'librarian', is_active = 1 }) => {
    if (!['admin', 'librarian'].includes(role)) {
        throw new Error('Quản lý tài khoản chỉ tạo được tài khoản thủ thư hoặc quản trị viên!');
    }
    if (!password || String(password).length < 8) {
        throw new Error('Mật khẩu phải có tối thiểu 8 ký tự!');
    }
    if (![true, false, 1, 0].includes(is_active)) {
        throw new Error('Trạng thái tài khoản không hợp lệ!');
    }
    const cleanUsername = String(username || '').trim();
    if (!cleanUsername) throw new Error('Tên đăng nhập không được để trống!');
    const [existing] = await db.query('SELECT user_id FROM users WHERE username = ?', [cleanUsername]);
    if (existing.length > 0) {
        throw new Error('Tên đăng nhập này đã tồn tại!');
    }

    const cleanEmail = email && email.trim() ? email.trim().toLowerCase() : null;
    if (cleanEmail) {
        const [existingEmail] = await db.query(
            `SELECT u.user_id
             FROM users u
             LEFT JOIN readers r ON r.user_id = u.user_id
             WHERE u.email = ? OR r.email = ?
             UNION ALL
             SELECT CONCAT('reader:', r2.reader_id) AS user_id
             FROM readers r2
             WHERE r2.email = ? AND r2.user_id IS NULL
             LIMIT 1`,
            [cleanEmail, cleanEmail, cleanEmail]
        );
        if (existingEmail.length > 0) {
            throw new Error('Email này đã được sử dụng!');
        }
    }

    const userId = uuidv4();
    const passwordHash = await bcrypt.hash(password, 10);

    const sql = 'INSERT INTO users (user_id, username, email, full_name, phone, password_hash, role, is_active) VALUES (?, ?, ?, ?, ?, ?, ?, ?)';
    const normalizedIsActive = is_active === true || is_active === 1;
    await db.query(sql, [userId, cleanUsername, cleanEmail, full_name || null, phone || null, passwordHash, role, normalizedIsActive ? 1 : 0]);

    return {
        user_id: userId,
        username: cleanUsername,
        email: cleanEmail,
        full_name: full_name || null,
        phone: phone || null,
        role,
        is_active: normalizedIsActive
    };
};

/**
 * 4. Đổi vai trò tài khoản (Phân quyền)
 */
exports.updateRole = async (userId, newRole) => {
    if (!['admin', 'librarian'].includes(newRole)) {
        throw new Error('Vai trò không hợp lệ! Chỉ chấp nhận admin hoặc librarian.');
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
