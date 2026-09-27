const db = require('../../config/db');
const { v4: uuidv4 } = require('uuid');
const publishersService = require('../publishers/publishers.service');
const categoriesService = require('../categories/categories.service');

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
exports.searchBooks = async ({
    keyword = '',
    ddc_class = '',
    author = '',
    subject = '',
    language = '',
    publish_year = '',
    page = 1,
    limit = 10
}) => {
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

    if (author.trim()) {
        whereConditions.push('b.authors LIKE ?');
        params.push(`%${author.trim()}%`);
    }

    if (subject.trim()) {
        whereConditions.push('b.subject_headings LIKE ?');
        params.push(`%${subject.trim()}%`);
    }

    if (language.trim()) {
        whereConditions.push('b.language = ?');
        params.push(language.trim());
    }

    if (String(publish_year).trim()) {
        const normalizedYear = Number(publish_year);
        if (!Number.isInteger(normalizedYear) || normalizedYear < 1000 || normalizedYear > 9999) {
            throw new Error('Năm xuất bản không hợp lệ!');
        }
        whereConditions.push('b.publish_year = ?');
        params.push(normalizedYear);
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
        publisher_name = null,
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

    // 1. Tự động tìm hoặc tạo Nhà xuất bản nếu chưa có
    let resolvedPublisherId = publisher_id;
    if (!resolvedPublisherId && publisher_name && publisher_name.trim()) {
        const pub = await publishersService.findOrCreatePublisher(publisher_name);
        if (pub) resolvedPublisherId = pub.publisher_id;
    }

    // 2. Tự động tìm hoặc tạo Thể loại nếu có truyền subject_headings
    const parsedSubjects = typeof subject_headings === 'string' ? parseJSONField(subject_headings, []) : subject_headings;
    if (Array.isArray(parsedSubjects) && parsedSubjects.length > 0) {
        for (const catName of parsedSubjects) {
            if (typeof catName === 'string' && catName.trim()) {
                await categoriesService.findOrCreateCategory(catName, ddc_class);
            }
        }
    }

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
        bibId, isbn, title, subtitle, authorsJSON, resolvedPublisherId,
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

/**
 * 9. Quét trực tiếp Barcode hoặc ISBN để định danh sách (Scan trực tiếp)
 * - Nếu là Barcode bản sao: Trả về thông tin sách + chi tiết bản sao và vị trí kệ sách
 * - Nếu là ISBN đầu sách: Trả về thông tin đầu sách + toàn bộ danh sách bản sao
 */
exports.scanBookByCode = async (rawCode) => {
    if (!rawCode || !rawCode.trim()) return null;
    const code = rawCode.trim();

    // 1. Ưu tiên tìm theo barcode của bản sao sách (book_copies)
    const copySql = `
        SELECT 
            c.copy_id,
            c.bib_id,
            c.barcode,
            c.condition,
            c.status,
            c.acquired_date,
            c.acquired_price,
            b.isbn,
            b.title,
            b.subtitle,
            b.authors,
            b.publisher_id,
            p.name AS publisher_name,
            b.publish_year,
            b.edition,
            b.language,
            b.description,
            b.page_count,
            b.call_number,
            b.ddc_class,
            b.subject_headings,
            b.keywords,
            b.cover_url,
            s.location_id,
            s.floor,
            s.section,
            s.shelf,
            s.position,
            s.ddc_range
        FROM book_copies c
        JOIN bibliographic_records b ON c.bib_id = b.bib_id
        LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
        LEFT JOIN shelf_locations s ON c.location_id = s.location_id
        WHERE c.barcode = ?
        LIMIT 1
    `;
    const [copyRows] = await db.query(copySql, [code]);

    if (copyRows.length > 0) {
        const row = copyRows[0];
        return {
            scan_type: 'copy',
            scanned_code: code,
            copy: {
                copy_id: row.copy_id,
                barcode: row.barcode,
                condition: row.condition,
                status: row.status,
                acquired_date: row.acquired_date,
                acquired_price: row.acquired_price,
                location: row.location_id ? {
                    location_id: row.location_id,
                    floor: row.floor,
                    section: row.section,
                    shelf: row.shelf,
                    position: row.position,
                    ddc_range: row.ddc_range
                } : null
            },
            book: {
                bib_id: row.bib_id,
                isbn: row.isbn,
                title: row.title,
                subtitle: row.subtitle,
                authors: parseJSONField(row.authors),
                publisher_id: row.publisher_id,
                publisher_name: row.publisher_name,
                publish_year: row.publish_year,
                edition: row.edition,
                language: row.language,
                description: row.description,
                page_count: row.page_count,
                call_number: row.call_number,
                ddc_class: row.ddc_class,
                subject_headings: parseJSONField(row.subject_headings),
                keywords: parseJSONField(row.keywords),
                cover_url: row.cover_url
            }
        };
    }

    // 2. Nếu không khớp barcode bản sao, kiểm tra khớp mã ISBN đầu sách (bibliographic_records)
    const cleanCode = code.replace(/[-\s]/g, '');
    const bookSql = `
        SELECT 
            b.*,
            p.name AS publisher_name
        FROM bibliographic_records b
        LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
        WHERE b.isbn = ? OR REPLACE(b.isbn, '-', '') = ?
        LIMIT 1
    `;
    const [bookRows] = await db.query(bookSql, [code, cleanCode]);

    if (bookRows.length > 0) {
        const book = bookRows[0];
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
        const [copies] = await db.query(copiesSql, [book.bib_id]);

        return {
            scan_type: 'book',
            scanned_code: code,
            book: {
                ...book,
                authors: parseJSONField(book.authors),
                subject_headings: parseJSONField(book.subject_headings),
                keywords: parseJSONField(book.keywords),
                metadata: parseJSONField(book.metadata, {}),
                total_copies: copies.length,
                available_copies: copies.filter((c) => c.status === 'available').length,
                copies
            }
        };
    }

    // 3. Không tìm thấy
    return null;
};

/**
 * 10. Tra cứu thông tin sách thật trên Internet qua mã ISBN (Google Books & Open Library)
 * Kiểm tra trạng thái NXB và Thể loại trong cơ sở dữ liệu nội bộ
 */
exports.lookupBookByIsbn = async (rawIsbn) => {
    if (!rawIsbn || !rawIsbn.trim()) {
        throw new Error('Vui lòng cung cấp mã ISBN cần tra cứu!');
    }
    const cleanIsbn = rawIsbn.trim().replace(/[-\s]/g, '');

    // 1. Kiểm tra xem sách này đã có trong thư viện chưa
    const [existingRows] = await db.query(
        `SELECT b.*, p.name AS publisher_name 
         FROM bibliographic_records b 
         LEFT JOIN publishers p ON b.publisher_id = p.publisher_id 
         WHERE b.isbn = ? OR REPLACE(b.isbn, '-', '') = ?
         LIMIT 1`,
        [rawIsbn.trim(), cleanIsbn]
    );

    let alreadyInLibrary = false;
    let existingBook = null;
    if (existingRows.length > 0) {
        alreadyInLibrary = true;
        const b = existingRows[0];
        existingBook = {
            bib_id: b.bib_id,
            isbn: b.isbn,
            title: b.title,
            publisher_name: b.publisher_name,
            publish_year: b.publish_year,
            cover_url: b.cover_url
        };
    }

    // 2. Tra cứu Internet từ Google Books và Open Library
    let bookData = null;

    // A. Thử Google Books API (hỗ trợ API Key nếu có cấu hình)
    try {
        const apiKey = process.env.GOOGLE_BOOKS_API_KEY ? `&key=${process.env.GOOGLE_BOOKS_API_KEY}` : '';
        const gRes = await fetch(`https://www.googleapis.com/books/v1/volumes?q=isbn:${cleanIsbn}${apiKey}`);
        if (gRes.ok) {
            const gData = await gRes.json();
            if (gData.items && gData.items.length > 0) {
                const info = gData.items[0].volumeInfo;
                bookData = {
                    source: 'google_books',
                    isbn: cleanIsbn,
                    title: info.title || null,
                    subtitle: info.subtitle || null,
                    authors: (info.authors || []).map((a) => ({ name: a, role: 'author' })),
                    publisher_name: info.publisher || null,
                    publish_year: info.publishedDate ? parseInt(info.publishedDate.slice(0, 4), 10) : null,
                    edition: null,
                    language: info.language || 'vi',
                    page_count: info.pageCount || null,
                    description: info.description || null,
                    cover_url: info.imageLinks ? (info.imageLinks.thumbnail || info.imageLinks.smallThumbnail || '').replace('http://', 'https://') : null,
                    categories: info.categories || []
                };
            }
        }
    } catch (_) {}

    // B. Dự phòng sang Open Library API nếu Google Books không có kết quả hoặc gặp lỗi
    if (!bookData) {
        try {
            const olRes = await fetch(`https://openlibrary.org/search.json?isbn=${cleanIsbn}`, {
                headers: { 'User-Agent': 'LibraryManagementApp/1.0 (contact@library.local)' }
            });
            if (olRes.ok) {
                const olData = await olRes.json();
                if (olData.docs && olData.docs.length > 0) {
                    const doc = olData.docs[0];
                    let description = null;
                    let publisher = doc.publisher && doc.publisher.length > 0 ? doc.publisher[0] : null;
                    let pageCount = doc.number_of_pages_median || null;

                    // Lấy thêm chi tiết từ endpoint /isbn/{cleanIsbn}.json
                    try {
                        const detailRes = await fetch(`https://openlibrary.org/isbn/${cleanIsbn}.json`, {
                            headers: { 'User-Agent': 'LibraryManagementApp/1.0' }
                        });
                        if (detailRes.ok) {
                            const detail = await detailRes.json();
                            if (detail.description) {
                                description = typeof detail.description === 'string' ? detail.description : detail.description.value;
                            }
                            if (!publisher && detail.publishers && detail.publishers.length > 0) {
                                publisher = detail.publishers[0];
                            }
                            if (!pageCount && detail.number_of_pages) {
                                pageCount = detail.number_of_pages;
                            }
                        }
                    } catch (_) {}

                    bookData = {
                        source: 'open_library',
                        isbn: cleanIsbn,
                        title: doc.title,
                        subtitle: doc.subtitle || null,
                        authors: (doc.author_name || []).map((a) => ({ name: a, role: 'author' })),
                        publisher_name: publisher,
                        publish_year: doc.first_publish_year || null,
                        edition: null,
                        language: doc.language && doc.language.length > 0 ? doc.language[0] : 'en',
                        page_count: pageCount,
                        description,
                        cover_url: doc.cover_i ? `https://covers.openlibrary.org/b/id/${doc.cover_i}-L.jpg` : `https://covers.openlibrary.org/b/isbn/${cleanIsbn}-L.jpg`,
                        categories: doc.subject ? doc.subject.slice(0, 5) : []
                    };
                }
            }
        } catch (_) {}
    }

    if (!bookData) {
        throw new Error('Không tìm thấy thông tin cuốn sách này trên cơ sở dữ liệu quốc tế! Bạn có thể nhập thông tin thủ công.');
    }

    // 3. Kiểm tra xem Nhà xuất bản đã có trong bảng publishers chưa
    let publisherInfo = {
        name: bookData.publisher_name,
        in_db: false,
        publisher_id: null
    };
    if (bookData.publisher_name) {
        const [pubRows] = await db.query(
            'SELECT publisher_id, name FROM publishers WHERE LOWER(name) = LOWER(?) LIMIT 1',
            [bookData.publisher_name.trim()]
        );
        if (pubRows.length > 0) {
            publisherInfo.in_db = true;
            publisherInfo.publisher_id = pubRows[0].publisher_id;
            publisherInfo.name = pubRows[0].name;
        }
    }

    // 4. Kiểm tra xem các Thể loại đã có trong bảng categories chưa
    const categoriesInfo = [];
    if (bookData.categories && bookData.categories.length > 0) {
        for (const cat of bookData.categories) {
            const [catRows] = await db.query(
                'SELECT category_id, category_name FROM categories WHERE LOWER(category_name) = LOWER(?) LIMIT 1',
                [cat.trim()]
            );
            categoriesInfo.push({
                name: cat,
                in_db: catRows.length > 0,
                category_id: catRows.length > 0 ? catRows[0].category_id : null
            });
        }
    }

    return {
        source: bookData.source,
        already_in_library: alreadyInLibrary,
        existing_book: existingBook,
        book_info: {
            ...bookData,
            publisher_status: publisherInfo,
            categories_status: categoriesInfo
        }
    };
};
