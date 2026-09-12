const db = require('../../config/db');
const { v4: uuidv4 } = require('uuid');

/**
 * Hàm hỗ trợ parse trường JSON an toàn
 */
const parseJSONField = (data, defaultValue = []) => {
    if (!data) return defaultValue;
    if (typeof data === 'object') return data;
    try {
        return JSON.parse(data);
    } catch {
        return defaultValue;
    }
};

/**
 * 1. Tìm kiếm và lọc danh sách sách (Phân trang)
 */
exports.searchBooks = async ({ keyword = '', ddc_class = '', page = 1, limit = 10 }) => {
    const offset = (page - 1) * limit;
    const params = [];
    let whereConditions = [];

    // Tìm kiếm theo từ khóa (tên sách, tác giả, ISBN, mô tả)
    if (keyword.trim()) {
        whereConditions.push('(b.title LIKE ? OR b.isbn LIKE ? OR b.authors LIKE ? OR b.description LIKE ?)');
        const searchPattern = `%${keyword.trim()}%`;
        params.push(searchPattern, searchPattern, searchPattern, searchPattern);
    }

    // Lọc theo mã phân loại Dewey (DDC)
    if (ddc_class.trim()) {
        whereConditions.push('b.ddc_class LIKE ?');
        params.push(`${ddc_class.trim()}%`);
    }

    const whereClause = whereConditions.length > 0 ? `WHERE ${whereConditions.join(' AND ')}` : '';

    // Đếm tổng số lượng bản ghi thỏa mãn
    const countSql = `SELECT COUNT(*) AS total FROM bibliographic_records b ${whereClause}`;
    const [countResult] = await db.query(countSql, params);
    const total = countResult[0].total;

    // Truy vấn dữ liệu sách kèm số lượng bản sao khả dụng
    const sql = `
        SELECT 
            b.bib_id,
            b.isbn,
            b.title,
            b.subtitle,
            b.authors,
            b.publisher_id,
            b.publish_year,
            b.edition,
            b.language,
            b.description,
            b.page_count,
            b.call_number,
            b.ddc_class,
            b.subject_headings,
            b.cover_url,
            b.created_at,
            COUNT(c.copy_id) AS total_copies,
            SUM(CASE WHEN c.status = 'available' THEN 1 ELSE 0 END) AS available_copies
        FROM bibliographic_records b
        LEFT JOIN book_copies c ON b.bib_id = c.bib_id
        ${whereClause}
        GROUP BY b.bib_id
        ORDER BY b.created_at DESC
        LIMIT ? OFFSET ?
    `;

    const [rows] = await db.query(sql, [...params, Number(limit), Number(offset)]);

    const books = rows.map((book) => ({
        ...book,
        authors: parseJSONField(book.authors),
        subject_headings: parseJSONField(book.subject_headings),
        total_copies: Number(book.total_copies) || 0,
        available_copies: Number(book.available_copies) || 0
    }));

    return {
        total,
        page: Number(page),
        limit: Number(limit),
        totalPages: Math.ceil(total / limit),
        items: books
    };
};

/**
 * 2. Xem chi tiết sách theo ID (Bao gồm danh sách bản sao vật lý & vị trí kệ)
 */
exports.getBookById = async (bibId) => {
    // Lấy thông tin đầu sách
    const bookSql = `
        SELECT 
            b.*,
            p.name AS publisher_name
        FROM bibliographic_records b
        LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
        WHERE b.bib_id = ?
    `;
    const [bookRows] = await db.query(bookSql, [bibId]);

    if (bookRows.length === 0) return null;

    const book = bookRows[0];

    // Lấy danh sách các bản sao vật lý và vị trí kệ sách
    const copiesSql = `
        SELECT 
            c.copy_id,
            c.barcode,
            c.condition,
            c.status,
            c.acquired_date,
            c.acquired_price,
            s.location_id,
            s.floor,
            s.section,
            s.shelf,
            s.position,
            s.ddc_range
        FROM book_copies c
        LEFT JOIN shelf_locations s ON c.location_id = s.location_id
        WHERE c.bib_id = ?
        ORDER BY c.barcode ASC
    `;
    const [copiesRows] = await db.query(copiesSql, [bibId]);

    const totalCopies = copiesRows.length;
    const availableCopies = copiesRows.filter((copy) => copy.status === 'available').length;

    return {
        ...book,
        authors: parseJSONField(book.authors),
        subject_headings: parseJSONField(book.subject_headings),
        keywords: parseJSONField(book.keywords),
        metadata: parseJSONField(book.metadata, {}),
        total_copies: totalCopies,
        available_copies: availableCopies,
        copies: copiesRows
    };
};

/**
 * 3. Thêm mới sách (Thủ thư)
 */
exports.createBook = async (bookData) => {
    const bibId = uuidv4();
    const {
        isbn,
        title,
        subtitle = null,
        authors = [],
        publisher_id = null,
        publish_year = null,
        edition = null,
        language = 'vi',
        description = null,
        page_count = null,
        call_number = null,
        ddc_class = null,
        subject_headings = [],
        keywords = [],
        cover_url = null,
        metadata = {},
        initial_copies = 0,
        location_id = null
    } = bookData;

    const authorsJSON = typeof authors === 'string' ? authors : JSON.stringify(authors);
    const subjectsJSON = typeof subject_headings === 'string' ? subject_headings : JSON.stringify(subject_headings);
    const keywordsJSON = typeof keywords === 'string' ? keywords : JSON.stringify(keywords);
    const metadataJSON = typeof metadata === 'string' ? metadata : JSON.stringify(metadata);

    const insertSql = `
        INSERT INTO bibliographic_records (
            bib_id, isbn, title, subtitle, authors, publisher_id,
            publish_year, edition, language, description, page_count,
            call_number, ddc_class, subject_headings, keywords, cover_url, metadata
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    await db.query(insertSql, [
        bibId, isbn, title, subtitle, authorsJSON, publisher_id,
        publish_year, edition, language, description, page_count,
        call_number, ddc_class, subjectsJSON, keywordsJSON, cover_url, metadataJSON
    ]);

    // Tạo các bản sao sách nếu có chỉ định initial_copies
    const createdCopies = [];
    if (initial_copies > 0) {
        for (let i = 1; i <= initial_copies; i++) {
            const copyId = uuidv4();
            const barcode = `BC-${Date.now().toString().slice(-6)}-${i.toString().padStart(2, '0')}`;
            const copySql = `
                INSERT INTO book_copies (copy_id, bib_id, barcode, \`condition\`, location_id, status, acquired_date)
                VALUES (?, ?, ?, 'good', ?, 'available', CURDATE())
            `;
            await db.query(copySql, [copyId, bibId, barcode, location_id]);
            createdCopies.push({ copy_id: copyId, barcode });
        }
    }

    return {
        bib_id: bibId,
        title,
        isbn,
        created_copies_count: createdCopies.length,
        copies: createdCopies
    };
};

/**
 * 4. Cập nhật thông tin sách (Thủ thư)
 */
exports.updateBook = async (bibId, updateData) => {
    // Kiểm tra sách tồn tại
    const [existing] = await db.query('SELECT bib_id FROM bibliographic_records WHERE bib_id = ?', [bibId]);
    if (existing.length === 0) return null;

    const fields = [];
    const values = [];

    const allowedFields = [
        'isbn', 'title', 'subtitle', 'publisher_id', 'publish_year',
        'edition', 'language', 'description', 'page_count', 'call_number',
        'ddc_class', 'cover_url'
    ];

    allowedFields.forEach((field) => {
        if (updateData[field] !== undefined) {
            fields.push(`${field} = ?`);
            values.push(updateData[field]);
        }
    });

    if (updateData.authors !== undefined) {
        fields.push('authors = ?');
        values.push(typeof updateData.authors === 'string' ? updateData.authors : JSON.stringify(updateData.authors));
    }
    if (updateData.subject_headings !== undefined) {
        fields.push('subject_headings = ?');
        values.push(typeof updateData.subject_headings === 'string' ? updateData.subject_headings : JSON.stringify(updateData.subject_headings));
    }
    if (updateData.keywords !== undefined) {
        fields.push('keywords = ?');
        values.push(typeof updateData.keywords === 'string' ? updateData.keywords : JSON.stringify(updateData.keywords));
    }
    if (updateData.metadata !== undefined) {
        fields.push('metadata = ?');
        values.push(typeof updateData.metadata === 'string' ? updateData.metadata : JSON.stringify(updateData.metadata));
    }

    if (fields.length === 0) return true;

    values.push(bibId);
    const updateSql = `UPDATE bibliographic_records SET ${fields.join(', ')} WHERE bib_id = ?`;
    await db.query(updateSql, values);

    return true;
};

/**
 * 5. Xóa sách (Thủ thư)
 */
exports.deleteBook = async (bibId) => {
    // Kiểm tra xem có bản sao nào đang được mượn không
    const [borrowed] = await db.query(
        "SELECT copy_id FROM book_copies WHERE bib_id = ? AND status = 'borrowed'",
        [bibId]
    );

    if (borrowed.length > 0) {
        throw new Error('Không thể xóa đầu sách vì đang có bản sao được mượn!');
    }

    // Xóa đầu sách (các bản sao sẽ tự động xóa nhờ ON DELETE CASCADE)
    const [result] = await db.query('DELETE FROM bibliographic_records WHERE bib_id = ?', [bibId]);
    return result.affectedRows > 0;
};

/**
 * 6. Lấy danh sách bản sao vật lý của 1 cuốn sách
 */
exports.getBookCopies = async (bibId) => {
    const sql = `
        SELECT 
            c.*, 
            s.floor, s.section, s.shelf, s.position
        FROM book_copies c
        LEFT JOIN shelf_locations s ON c.location_id = s.location_id
        WHERE c.bib_id = ?
        ORDER BY c.barcode ASC
    `;
    const [rows] = await db.query(sql, [bibId]);
    return rows;
};

/**
 * 7. Cập nhật tình trạng & trạng thái của bản sao sách (Thủ thư đi kiểm kê tại giá)
 */
exports.updateCopyCondition = async (copyId, { condition, status, location_id }) => {
    const fields = [];
    const values = [];

    if (condition) {
        fields.push('`condition` = ?');
        values.push(condition);
    }
    if (status) {
        fields.push('status = ?');
        values.push(status);
    }
    if (location_id) {
        fields.push('location_id = ?');
        values.push(location_id);
    }

    if (fields.length === 0) return false;

    values.push(copyId);
    const sql = `UPDATE book_copies SET ${fields.join(', ')} WHERE copy_id = ?`;
    const [result] = await db.query(sql, values);
    return result.affectedRows > 0;
};

/**
 * 8. Thêm bản sao vật lý mới cho sách có sẵn
 */
exports.addCopy = async (bibId, { barcode, condition = 'good', location_id = null, acquired_price = 0 }) => {
    const copyId = uuidv4();
    const finalBarcode = barcode || `BC-${Date.now().toString().slice(-8)}`;

    const sql = `
        INSERT INTO book_copies (copy_id, bib_id, barcode, \`condition\`, location_id, status, acquired_date, acquired_price)
        VALUES (?, ?, ?, ?, ?, 'available', CURDATE(), ?)
    `;
    await db.query(sql, [copyId, bibId, finalBarcode, condition, location_id, acquired_price]);

    return {
        copy_id: copyId,
        barcode: finalBarcode,
        condition,
        status: 'available'
    };
};
