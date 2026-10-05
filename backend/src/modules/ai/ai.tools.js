const db = require('../../config/db');

const parseJSONField = (value, fallback = []) => {
    if (!value) return fallback;
    if (typeof value === 'object') return value;
    try {
        return JSON.parse(value);
    } catch {
        return fallback;
    }
};

/**
 * 1. Tim kiem dau sach
 */
async function searchBooks({ keyword, limit = 5 }) {
    const cleanLimit = Math.min(Math.max(1, parseInt(limit, 10) || 5), 10);
    const cleanKeyword = String(keyword || '').trim();
    if (!cleanKeyword) {
        return { total_found: 0, books: [], message: 'Vui lòng cung cấp từ khóa tìm sách.' };
    }
    const sql = `
        SELECT 
            br.bib_id,
            br.title,
            br.authors,
            br.isbn,
            br.publish_year,
            p.name AS publisher_name,
            br.subject_headings
        FROM bibliographic_records br
        LEFT JOIN publishers p ON br.publisher_id = p.publisher_id
        WHERE br.title LIKE ? OR br.authors LIKE ? OR br.isbn LIKE ?
        LIMIT ?
    `;
    const term = `%${cleanKeyword}%`;
    const [rows] = await db.query(sql, [term, term, term, cleanLimit]);
    return {
        total_found: rows.length,
        books: rows.map(row => ({
            ...row,
            authors: parseJSONField(row.authors),
            subject_headings: parseJSONField(row.subject_headings)
        }))
    };
}

/**
 * 2. Kiem tra so luong ban sao san co va vi tri ke sach
 */
async function getBookAvailability({ title, isbn }) {
    let whereClause = '';
    const params = [];

    if (isbn) {
        whereClause = 'WHERE br.isbn = ?';
        params.push(isbn.trim());
    } else if (title) {
        whereClause = 'WHERE br.title LIKE ?';
        params.push(`%${title.trim()}%`);
    } else {
        return { message: 'Vui long cung cap ten sach hoac ma ISBN de kiem tra!' };
    }

    const sql = `
        SELECT 
            br.bib_id,
            br.title,
            br.isbn,
            bc.copy_id,
            bc.barcode,
            bc.status AS copy_status,
            bc.condition AS copy_condition,
            s.floor,
            s.section,
            s.shelf,
            s.position
        FROM bibliographic_records br
        JOIN book_copies bc ON br.bib_id = bc.bib_id
        LEFT JOIN shelf_locations s ON bc.location_id = s.location_id
        ${whereClause}
        LIMIT 20
    `;

    const [rows] = await db.query(sql, params);

    if (rows.length === 0) {
        return { message: 'Khong tim thay ban sao vat ly nao cho cuon sach nay trong thu vien.' };
    }

    const availableCopies = rows.filter(r => r.copy_status === 'available');
    const borrowedCopies = rows.filter(r => r.copy_status === 'borrowed');

    return {
        book_title: rows[0].title,
        isbn: rows[0].isbn,
        total_copies: rows.length,
        available_count: availableCopies.length,
        borrowed_count: borrowedCopies.length,
        available_locations: availableCopies.map(c => ({
            barcode: c.barcode,
            condition: c.copy_condition,
            shelf: c.shelf || 'Chưa xếp vào kệ',
            location: [c.floor, c.section, c.shelf, c.position]
                .filter(Boolean)
                .join(' - ') || 'Kho sách'
        }))
    };
}

/**
 * 3. Lay danh sach cac luot muon qua han
 */
async function getOverdueLoans({ limit = 10 }) {
    const cleanLimit = Math.min(Math.max(1, parseInt(limit, 10) || 10), 20);
    const sql = `
        SELECT 
            bt.tx_id,
            r.full_name AS reader_name,
            r.reader_code,
            r.phone,
            br.title AS book_title,
            bc.barcode,
            bt.borrow_date,
            bt.due_date,
            DATEDIFF(CURDATE(), bt.due_date) AS days_overdue,
            (DATEDIFF(CURDATE(), bt.due_date) * 2000) AS estimated_fine
        FROM borrow_transactions bt
        JOIN readers r ON bt.reader_id = r.reader_id
        JOIN book_copies bc ON bt.copy_id = bc.copy_id
        JOIN bibliographic_records br ON bc.bib_id = br.bib_id
        WHERE bt.due_date < CURDATE()
          AND bt.status IN ('borrowed', 'overdue')
          AND bt.return_date IS NULL
        ORDER BY days_overdue DESC
        LIMIT ?
    `;

    const [rows] = await db.query(sql, [cleanLimit]);

    return {
        overdue_count: rows.length,
        loans: rows.map(r => ({
            tx_id: r.tx_id,
            reader_name: r.reader_name,
            reader_code: r.reader_code,
            book_title: r.book_title,
            barcode: r.barcode,
            due_date: new Date(r.due_date).toLocaleDateString('vi-VN'),
            days_overdue: r.days_overdue,
            estimated_fine_vnd: r.estimated_fine
        }))
    };
}

/**
 * 4. Lay danh sach cac luot muon sap den han tra
 */
async function getLoansDueSoon({ days = 2, limit = 10 }) {
    const cleanDays = Math.min(Math.max(1, parseInt(days, 10) || 2), 7);
    const cleanLimit = Math.min(Math.max(1, parseInt(limit, 10) || 10), 20);

    const sql = `
        SELECT 
            bt.tx_id,
            r.full_name AS reader_name,
            r.reader_code,
            br.title AS book_title,
            bc.barcode,
            bt.borrow_date,
            bt.due_date,
            DATEDIFF(bt.due_date, CURDATE()) AS days_left
        FROM borrow_transactions bt
        JOIN readers r ON bt.reader_id = r.reader_id
        JOIN book_copies bc ON bt.copy_id = bc.copy_id
        JOIN bibliographic_records br ON bc.bib_id = br.bib_id
        WHERE bt.due_date >= CURDATE()
          AND bt.due_date <= DATE_ADD(CURDATE(), INTERVAL ? DAY)
          AND bt.status = 'borrowed'
          AND bt.return_date IS NULL
        ORDER BY bt.due_date ASC
        LIMIT ?
    `;

    const [rows] = await db.query(sql, [cleanDays, cleanLimit]);

    return {
        due_soon_count: rows.length,
        loans: rows.map(r => ({
            tx_id: r.tx_id,
            reader_name: r.reader_name,
            reader_code: r.reader_code,
            book_title: r.book_title,
            barcode: r.barcode,
            due_date: new Date(r.due_date).toLocaleDateString('vi-VN'),
            days_left: r.days_left === 0 ? 'Het han hom nay' : `Con ${r.days_left} ngay`
        }))
    };
}

/**
 * 5. Lay danh sach cac sach dang duoc muon
 */
async function getActiveLoans({ reader_name, limit = 10 }) {
    const cleanLimit = Math.min(Math.max(1, parseInt(limit, 10) || 10), 20);
    let whereClause = "WHERE bt.status IN ('borrowed', 'overdue') AND bt.return_date IS NULL";
    const params = [];

    if (reader_name) {
        whereClause += ' AND r.full_name LIKE ?';
        params.push(`%${reader_name.trim()}%`);
    }

    const sql = `
        SELECT 
            bt.tx_id,
            r.full_name AS reader_name,
            r.reader_code,
            br.title AS book_title,
            bc.barcode,
            bt.borrow_date,
            bt.due_date,
            bt.status
        FROM borrow_transactions bt
        JOIN readers r ON bt.reader_id = r.reader_id
        JOIN book_copies bc ON bt.copy_id = bc.copy_id
        JOIN bibliographic_records br ON bc.bib_id = br.bib_id
        ${whereClause}
        ORDER BY bt.borrow_date DESC
        LIMIT ?
    `;

    const [rows] = await db.query(sql, [...params, cleanLimit]);

    return {
        total_active: rows.length,
        loans: rows.map(r => ({
            tx_id: r.tx_id,
            reader_name: r.reader_name,
            reader_code: r.reader_code,
            book_title: r.book_title,
            barcode: r.barcode,
            borrow_date: new Date(r.borrow_date).toLocaleDateString('vi-VN'),
            due_date: new Date(r.due_date).toLocaleDateString('vi-VN'),
            status: r.status
        }))
    };
}

/**
 * 6. Tra cuu tom tat ho so doc gia
 */
async function getReaderSummary({ keyword }) {
    const cleanKeyword = String(keyword || '').trim();
    if (!cleanKeyword) {
        return { matched_readers: [], message: 'Vui lòng cung cấp tên hoặc mã độc giả.' };
    }
    const sql = `
        SELECT 
            r.reader_id,
            r.reader_code,
            r.full_name,
            r.status AS card_status,
            r.card_expired,
            r.max_books,
            (
                SELECT COUNT(*) 
                FROM borrow_transactions 
                WHERE reader_id = r.reader_id AND status IN ('borrowed', 'overdue') AND return_date IS NULL
            ) AS active_borrow_count,
            (
                SELECT COUNT(*) 
                FROM borrow_transactions 
                WHERE reader_id = r.reader_id AND status = 'overdue' AND return_date IS NULL
            ) AS overdue_borrow_count,
            (
                SELECT COALESCE(SUM(fine_amount), 0) 
                FROM borrow_transactions 
                WHERE reader_id = r.reader_id AND fine_paid = 0
            ) AS unpaid_fines_total
        FROM readers r
        WHERE r.reader_code = ? OR r.full_name LIKE ?
        LIMIT 3
    `;

    const term = `%${cleanKeyword}%`;
    const [rows] = await db.query(sql, [cleanKeyword, term]);

    if (rows.length === 0) {
        return { message: `Không tìm thấy thông tin độc giả nào với từ khóa "${cleanKeyword}".` };
    }

    return {
        matched_readers: rows.map(r => ({
            reader_id: r.reader_id,
            reader_code: r.reader_code,
            full_name: r.full_name,
            card_status: r.card_status,
            card_expired: r.card_expired ? new Date(r.card_expired).toLocaleDateString('vi-VN') : 'Khong thoi han',
            active_borrow_count: r.active_borrow_count,
            overdue_borrow_count: r.overdue_borrow_count,
            unpaid_fines_vnd: r.unpaid_fines_total
        }))
    };
}

/**
 * 7. Thong ke tong quan toan thu vien (Dashboard)
 */
async function getDashboardStatistics() {
    const [books] = await db.query('SELECT COUNT(*) AS total_books FROM bibliographic_records');
    const [copies] = await db.query('SELECT COUNT(*) AS total_copies, SUM(status = "available") AS available_copies, SUM(status = "borrowed") AS borrowed_copies FROM book_copies');
    const [readers] = await db.query('SELECT COUNT(*) AS total_readers, SUM(status = "active") AS active_readers FROM readers');
    const [loans] = await db.query(`
        SELECT 
            COUNT(*) AS total_active_loans,
            SUM(status = "overdue" OR due_date < CURDATE()) AS overdue_loans,
            COALESCE(SUM(CASE WHEN fine_paid = 0 THEN fine_amount ELSE 0 END), 0) AS unpaid_fines
        FROM borrow_transactions 
        WHERE status IN ('borrowed', 'overdue') AND return_date IS NULL
    `);

    return {
        total_titles: books[0].total_books,
        total_physical_copies: copies[0].total_copies,
        available_copies: copies[0].available_copies || 0,
        currently_borrowed_copies: copies[0].borrowed_copies || 0,
        total_registered_readers: readers[0].total_readers,
        active_card_readers: readers[0].active_readers || 0,
        current_active_loans: loans[0].total_active_loans || 0,
        overdue_loans_count: loans[0].overdue_loans || 0,
        unpaid_fines_vnd: loans[0].unpaid_fines || 0
    };
}

/**
 * 8. Top sach duoc muon nhieu nhat
 */
async function getPopularBooks({ limit = 5 }) {
    const cleanLimit = Math.min(Math.max(1, parseInt(limit, 10) || 5), 10);
    const sql = `
        SELECT 
            br.bib_id,
            br.title,
            br.authors,
            br.isbn,
            COUNT(bt.tx_id) AS borrow_count
        FROM bibliographic_records br
        JOIN book_copies bc ON br.bib_id = bc.bib_id
        JOIN borrow_transactions bt ON bc.copy_id = bt.copy_id
        GROUP BY br.bib_id, br.title, br.authors, br.isbn
        ORDER BY borrow_count DESC
        LIMIT ?
    `;

    const [rows] = await db.query(sql, [cleanLimit]);

    return {
        popular_books: rows.map(row => ({
            ...row,
            authors: parseJSONField(row.authors)
        }))
    };
}

/**
 * 9. Danh sach cac khoan tien phat chua thu
 */
async function getUnpaidFines({ limit = 10 }) {
    const cleanLimit = Math.min(Math.max(1, parseInt(limit, 10) || 10), 20);
    const sql = `
        SELECT 
            bt.tx_id,
            r.full_name AS reader_name,
            r.reader_code,
            br.title AS book_title,
            bt.fine_amount,
            bt.due_date,
            bt.return_date,
            bt.status
        FROM borrow_transactions bt
        JOIN readers r ON bt.reader_id = r.reader_id
        JOIN book_copies bc ON bt.copy_id = bc.copy_id
        JOIN bibliographic_records br ON bc.bib_id = br.bib_id
        WHERE bt.fine_amount > 0 AND bt.fine_paid = 0
        ORDER BY bt.fine_amount DESC
        LIMIT ?
    `;

    const [rows] = await db.query(sql, [cleanLimit]);

    return {
        unpaid_fines_count: rows.length,
        items: rows.map(r => ({
            tx_id: r.tx_id,
            reader_name: r.reader_name,
            reader_code: r.reader_code,
            book_title: r.book_title,
            fine_amount_vnd: r.fine_amount,
            status: r.status
        }))
    };
}

/**
 * 10. Danh sach the doc gia sap het han hoac da het han
 */
async function getExpiringReaderCards({ days = 30, limit = 10 }) {
    const cleanDays = Math.min(Math.max(1, parseInt(days, 10) || 30), 90);
    const cleanLimit = Math.min(Math.max(1, parseInt(limit, 10) || 10), 20);

    const sql = `
        SELECT 
            reader_id,
            reader_code,
            full_name,
            phone,
            status,
            card_expired,
            DATEDIFF(card_expired, CURDATE()) AS days_until_expiration
        FROM readers
        WHERE card_expired IS NOT NULL
          AND card_expired <= DATE_ADD(CURDATE(), INTERVAL ? DAY)
        ORDER BY card_expired ASC
        LIMIT ?
    `;

    const [rows] = await db.query(sql, [cleanDays, cleanLimit]);

    return {
        expiring_cards_count: rows.length,
        readers: rows.map(r => ({
            reader_id: r.reader_id,
            reader_code: r.reader_code,
            full_name: r.full_name,
            card_expired: new Date(r.card_expired).toLocaleDateString('vi-VN'),
            is_already_expired: r.days_until_expiration < 0,
            days_left: r.days_until_expiration >= 0 ? r.days_until_expiration : 0
        }))
    };
}

// Map cac ham de goi dong theo ten tool tra ve tu nha cung cap AI
const toolsMap = {
    searchBooks,
    getBookAvailability,
    getOverdueLoans,
    getLoansDueSoon,
    getActiveLoans,
    getReaderSummary,
    getDashboardStatistics,
    getPopularBooks,
    getUnpaidFines,
    getExpiringReaderCards
};

// Dinh nghia Function Declarations; provider se chuyen sang chuan OpenRouter
const functionDeclarations = [
    {
        name: 'searchBooks',
        description: 'Tìm kiếm đầu sách trong thư viện theo từ khóa (tựa đề, tác giả, mã ISBN)',
        parameters: {
            type: 'OBJECT',
            properties: {
                keyword: { type: 'STRING', description: 'Từ khóa tìm kiếm tựa đề sách, tác giả hoặc ISBN' },
                limit: { type: 'NUMBER', description: 'Số lượng kết quả tối đa (mặc định 5)' }
            },
            required: ['keyword']
        }
    },
    {
        name: 'getBookAvailability',
        description: 'Kiểm tra tình trạng sẵn sàng và vị trí kệ sách của một cuốn sách (còn bao nhiêu cuốn sẵn sàng, nằm ở kệ nào, vị trí nào)',
        parameters: {
            type: 'OBJECT',
            properties: {
                title: { type: 'STRING', description: 'Tên cuốn sách cần kiểm tra' },
                isbn: { type: 'STRING', description: 'Mã ISBN cuốn sách (nếu có)' }
            }
        }
    },
    {
        name: 'getOverdueLoans',
        description: 'Lấy danh sách các lượt mượn sách đang bị quá hạn trả, bao gồm tên độc giả, tên sách, số ngày quá hạn và tiền phạt tạm tính.',
        parameters: {
            type: 'OBJECT',
            properties: {
                limit: { type: 'NUMBER', description: 'Số lượng bản ghi tối đa cần lấy (mặc định 10)' }
            }
        }
    },
    {
        name: 'getLoansDueSoon',
        description: 'Lấy danh sách các lượt mượn sách sắp đến hạn phải trả trong số ngày tới (ví dụ: hôm nay hoặc 2 ngày tới).',
        parameters: {
            type: 'OBJECT',
            properties: {
                days: { type: 'NUMBER', description: 'Số ngày tới cần kiểm tra (mặc định 2)' },
                limit: { type: 'NUMBER', description: 'Số lượng bản ghi tối đa (mặc định 10)' }
            }
        }
    },
    {
        name: 'getActiveLoans',
        description: 'Lấy danh sách các lượt mượn sách đang diễn ra trong thư viện (chưa trả).',
        parameters: {
            type: 'OBJECT',
            properties: {
                reader_name: { type: 'STRING', description: 'Tên độc giả cần tìm (nếu có)' },
                limit: { type: 'NUMBER', description: 'Số lượng bản ghi tối đa (mặc định 10)' }
            }
        }
    },
    {
        name: 'getReaderSummary',
        description: 'Tra cứu tóm tắt hồ sơ độc giả: trạng thái thẻ thư viện, số sách đang mượn, sách quá hạn, tiền phạt chưa nộp.',
        parameters: {
            type: 'OBJECT',
            properties: {
                keyword: { type: 'STRING', description: 'Tên độc giả, mã thẻ hoặc mã sinh viên' }
            },
            required: ['keyword']
        }
    },
    {
        name: 'getDashboardStatistics',
        description: 'Lấy các số liệu thống kê tổng quan toàn thư viện: tổng số đầu sách, tổng bản sao, độc giả, sách đang mượn, quá hạn, tổng tiền phạt chưa thu.',
        parameters: {
            type: 'OBJECT',
            properties: {}
        }
    },
    {
        name: 'getPopularBooks',
        description: 'Lấy danh sách các cuốn sách được mượn nhiều nhất trong thư viện.',
        parameters: {
            type: 'OBJECT',
            properties: {
                limit: { type: 'NUMBER', description: 'Số lượng đầu sách cần lấy (mặc định 5)' }
            }
        }
    },
    {
        name: 'getUnpaidFines',
        description: 'Lấy danh sách các khoản tiền phạt trễ hạn hoặc làm hỏng/mất sách chưa được thanh toán.',
        parameters: {
            type: 'OBJECT',
            properties: {
                limit: { type: 'NUMBER', description: 'Số lượng bản ghi tối đa (mặc định 10)' }
            }
        }
    },
    {
        name: 'getExpiringReaderCards',
        description: 'Lấy danh sách thẻ thư viện của độc giả đã hết hạn hoặc sắp hết hạn trong số ngày tới.',
        parameters: {
            type: 'OBJECT',
            properties: {
                days: { type: 'NUMBER', description: 'Số ngày tới cần kiểm tra hết hạn (mặc định 30)' },
                limit: { type: 'NUMBER', description: 'Số lượng bản ghi tối đa (mặc định 10)' }
            }
        }
    }
];

module.exports = {
    toolsMap,
    functionDeclarations
};
