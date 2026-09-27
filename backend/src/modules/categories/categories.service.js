const db = require('../../config/db');
const { v4: uuidv4 } = require('uuid');

/**
 * 1. Lấy danh sách thể loại sách (hỗ trợ tìm kiếm theo tên hoặc mã DDC, phân trang)
 */
exports.getAllCategories = async ({ keyword = '', page = 1, limit = 50 }) => {
    const offset = (page - 1) * limit;
    const params = [];
    const where = [];

    if (keyword.trim()) {
        where.push('(category_name LIKE ? OR ddc_code LIKE ? OR description LIKE ?)');
        const kw = `%${keyword.trim()}%`;
        params.push(kw, kw, kw);
    }

    const whereClause = where.length > 0 ? `WHERE ${where.join(' AND ')}` : '';

    const countSql = `SELECT COUNT(*) AS total FROM categories ${whereClause}`;
    const [countRows] = await db.query(countSql, params);
    const total = countRows[0].total;

    const sql = `
        SELECT 
            category_id,
            category_name,
            ddc_code,
            description,
            created_at
        FROM categories
        ${whereClause}
        ORDER BY category_name ASC
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
 * 2. Xem chi tiết một thể loại
 */
exports.getCategoryById = async (categoryId) => {
    const [rows] = await db.query('SELECT * FROM categories WHERE category_id = ?', [categoryId]);
    if (rows.length === 0) return null;
    return rows[0];
};

/**
 * 3. Thêm thể loại mới (Thủ thư/Admin)
 */
exports.createCategory = async ({ category_name, ddc_code = null, description = null }) => {
    if (!category_name || !category_name.trim()) {
        throw new Error('Tên thể loại sách không được để trống!');
    }

    // Kiểm tra trùng tên thể loại
    const [existing] = await db.query('SELECT category_id FROM categories WHERE category_name = ?', [category_name.trim()]);
    if (existing.length > 0) {
        throw new Error(`Thể loại sách "${category_name.trim()}" đã tồn tại trong hệ thống!`);
    }

    const categoryId = uuidv4();
    const sql = `
        INSERT INTO categories (category_id, category_name, ddc_code, description, created_at)
        VALUES (?, ?, ?, ?, NOW())
    `;

    await db.query(sql, [categoryId, category_name.trim(), ddc_code ? ddc_code.trim() : null, description ? description.trim() : null]);

    return {
        category_id: categoryId,
        category_name: category_name.trim(),
        ddc_code: ddc_code ? ddc_code.trim() : null,
        description: description ? description.trim() : null,
        created_at: new Date()
    };
};

/**
 * 3.1. Tìm hoặc tạo mới thể loại sách nếu chưa tồn tại (Find or Create)
 */
exports.findOrCreateCategory = async (categoryName, ddcCode = null) => {
    if (!categoryName || !categoryName.trim()) return null;
    const cleanName = categoryName.trim();

    const [rows] = await db.query(
        'SELECT category_id, category_name, ddc_code FROM categories WHERE LOWER(category_name) = LOWER(?) LIMIT 1',
        [cleanName]
    );
    if (rows.length > 0) {
        return { category_id: rows[0].category_id, category_name: rows[0].category_name, ddc_code: rows[0].ddc_code, is_new: false };
    }

    const categoryId = uuidv4();
    await db.query(
        'INSERT INTO categories (category_id, category_name, ddc_code, description, created_at) VALUES (?, ?, ?, ?, NOW())',
        [categoryId, cleanName, ddcCode ? ddcCode.trim() : null, 'Thể loại tạo tự động từ thông tin sách']
    );

    return { category_id: categoryId, category_name: cleanName, ddc_code: ddcCode ? ddcCode.trim() : null, is_new: true };
};

/**
 * 4. Chỉnh sửa thông tin thể loại (Thủ thư/Admin)
 */
exports.updateCategory = async (categoryId, updateData) => {
    const [existing] = await db.query('SELECT category_id, category_name FROM categories WHERE category_id = ?', [categoryId]);
    if (existing.length === 0) {
        throw new Error('Không tìm thấy thể loại sách này!');
    }

    const fields = [];
    const values = [];

    if (updateData.category_name !== undefined) {
        if (!updateData.category_name.trim()) {
            throw new Error('Tên thể loại không được để trống!');
        }

        // Kiểm tra xem tên mới có trùng với thể loại khác không
        const [duplicate] = await db.query(
            'SELECT category_id FROM categories WHERE category_name = ? AND category_id != ?',
            [updateData.category_name.trim(), categoryId]
        );
        if (duplicate.length > 0) {
            throw new Error(`Tên thể loại "${updateData.category_name.trim()}" đã được sử dụng!`);
        }

        fields.push('category_name = ?');
        values.push(updateData.category_name.trim());
    }

    if (updateData.ddc_code !== undefined) {
        fields.push('ddc_code = ?');
        values.push(updateData.ddc_code ? updateData.ddc_code.trim() : null);
    }

    if (updateData.description !== undefined) {
        fields.push('description = ?');
        values.push(updateData.description ? updateData.description.trim() : null);
    }

    if (fields.length === 0) {
        return existing[0];
    }

    values.push(categoryId);
    const sql = `UPDATE categories SET ${fields.join(', ')} WHERE category_id = ?`;
    await db.query(sql, values);

    return await exports.getCategoryById(categoryId);
};

/**
 * 5. Xóa thể loại sách (Thủ thư/Admin)
 */
exports.deleteCategory = async (categoryId) => {
    const [existing] = await db.query('SELECT category_id FROM categories WHERE category_id = ?', [categoryId]);
    if (existing.length === 0) {
        throw new Error('Không tìm thấy thể loại sách này!');
    }

    await db.query('DELETE FROM categories WHERE category_id = ?', [categoryId]);

    return {
        category_id: categoryId,
        message: 'Đã xóa thể loại sách thành công'
    };
};
