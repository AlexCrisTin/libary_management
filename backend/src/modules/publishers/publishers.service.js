const db = require('../../config/db');
const { v4: uuidv4 } = require('uuid');

/**
 * 1. Lấy danh sách nhà xuất bản (kèm số lượng đầu sách đã xuất bản, hỗ trợ tìm kiếm và phân trang)
 */
exports.getAllPublishers = async ({ keyword = '', page = 1, limit = 50 }) => {
    const offset = (page - 1) * limit;
    const params = [];
    const where = [];

    if (keyword.trim()) {
        where.push('(p.name LIKE ? OR p.contact_email LIKE ? OR p.address LIKE ?)');
        const kw = `%${keyword.trim()}%`;
        params.push(kw, kw, kw);
    }

    const whereClause = where.length > 0 ? `WHERE ${where.join(' AND ')}` : '';

    const countSql = `SELECT COUNT(*) AS total FROM publishers p ${whereClause}`;
    const [countRows] = await db.query(countSql, params);
    const total = countRows[0].total;

    const sql = `
        SELECT 
            p.publisher_id,
            p.name,
            p.address,
            p.contact_email,
            p.created_at,
            COUNT(b.bib_id) AS book_count
        FROM publishers p
        LEFT JOIN bibliographic_records b ON p.publisher_id = b.publisher_id
        ${whereClause}
        GROUP BY p.publisher_id
        ORDER BY p.name ASC
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
 * 2. Xem chi tiết một nhà xuất bản và danh sách các đầu sách của NXB đó
 */
exports.getPublisherById = async (publisherId) => {
    const [publishers] = await db.query('SELECT * FROM publishers WHERE publisher_id = ?', [publisherId]);
    if (publishers.length === 0) return null;

    const publisher = publishers[0];

    // Lấy các đầu sách thuộc nhà xuất bản này
    const [books] = await db.query(
        `SELECT bib_id, isbn, title, publish_year, language, cover_url 
         FROM bibliographic_records 
         WHERE publisher_id = ? 
         ORDER BY publish_year DESC, title ASC`,
        [publisherId]
    );

    return {
        ...publisher,
        total_books: books.length,
        books
    };
};

/**
 * 3. Thêm nhà xuất bản mới (Thủ thư/Admin)
 */
exports.createPublisher = async ({ name, address = null, contact_email = null }) => {
    if (!name || !name.trim()) {
        throw new Error('Tên nhà xuất bản không được để trống!');
    }

    // Kiểm tra trùng tên nhà xuất bản
    const [existing] = await db.query('SELECT publisher_id FROM publishers WHERE name = ?', [name.trim()]);
    if (existing.length > 0) {
        throw new Error(`Nhà xuất bản "${name.trim()}" đã tồn tại trong hệ thống!`);
    }

    const publisherId = uuidv4();
    const sql = `
        INSERT INTO publishers (publisher_id, name, address, contact_email, created_at)
        VALUES (?, ?, ?, ?, NOW())
    `;

    await db.query(sql, [publisherId, name.trim(), address ? address.trim() : null, contact_email ? contact_email.trim() : null]);

    return {
        publisher_id: publisherId,
        name: name.trim(),
        address: address ? address.trim() : null,
        contact_email: contact_email ? contact_email.trim() : null,
        created_at: new Date()
    };
};

/**
 * 4. Chỉnh sửa thông tin nhà xuất bản (Thủ thư/Admin)
 */
exports.updatePublisher = async (publisherId, updateData) => {
    const [existing] = await db.query('SELECT * FROM publishers WHERE publisher_id = ?', [publisherId]);
    if (existing.length === 0) {
        throw new Error('Không tìm thấy nhà xuất bản này!');
    }

    const fields = [];
    const values = [];

    if (updateData.name !== undefined) {
        if (!updateData.name.trim()) {
            throw new Error('Tên nhà xuất bản không được để trống!');
        }

        const [duplicate] = await db.query(
            'SELECT publisher_id FROM publishers WHERE name = ? AND publisher_id != ?',
            [updateData.name.trim(), publisherId]
        );
        if (duplicate.length > 0) {
            throw new Error(`Tên nhà xuất bản "${updateData.name.trim()}" đã được sử dụng!`);
        }

        fields.push('name = ?');
        values.push(updateData.name.trim());
    }

    if (updateData.address !== undefined) {
        fields.push('address = ?');
        values.push(updateData.address ? updateData.address.trim() : null);
    }

    if (updateData.contact_email !== undefined) {
        fields.push('contact_email = ?');
        values.push(updateData.contact_email ? updateData.contact_email.trim() : null);
    }

    if (fields.length === 0) {
        return existing[0];
    }

    values.push(publisherId);
    const sql = `UPDATE publishers SET ${fields.join(', ')} WHERE publisher_id = ?`;
    await db.query(sql, values);

    return await exports.getPublisherById(publisherId);
};

/**
 * 5. Xóa nhà xuất bản (Thủ thư/Admin)
 * (Nhờ khóa ngoại ON DELETE SET NULL, các đầu sách liên quan sẽ tự động chuyển publisher_id thành NULL)
 */
exports.deletePublisher = async (publisherId) => {
    const [existing] = await db.query('SELECT publisher_id FROM publishers WHERE publisher_id = ?', [publisherId]);
    if (existing.length === 0) {
        throw new Error('Không tìm thấy nhà xuất bản này!');
    }

    await db.query('DELETE FROM publishers WHERE publisher_id = ?', [publisherId]);

    return {
        publisher_id: publisherId,
        message: 'Đã xóa nhà xuất bản thành công (các đầu sách đã liên kết được chuyển về NXB mặc định)'
    };
};
