const db = require('../../config/db');

const parseJSON = (value, fallback = []) => {
    if (!value) return fallback;
    if (Array.isArray(value) || typeof value === 'object') return value;
    try {
        return JSON.parse(value);
    } catch {
        return fallback;
    }
};

const dateKey = (date) => {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
};

const normalizeDate = (value) => {
    if (!value) return '';
    if (typeof value === 'string') return value.slice(0, 10);
    return dateKey(new Date(value));
};

exports.getStatistics = async ({ days = 7 }) => {
    const [
        [summaryRows],
        [borrowRows],
        [returnRows],
        [catalogRows],
        [topBooksRows],
        [topReadersRows]
    ] = await Promise.all([
        db.query(`
            SELECT
                (SELECT COUNT(*) FROM borrow_transactions
                 WHERE status IN ('borrowed', 'overdue')) AS active_loans,
                (SELECT COUNT(*) FROM borrow_transactions
                 WHERE status IN ('borrowed', 'overdue') AND due_date < CURDATE()) AS overdue_loans,
                (SELECT COUNT(*) FROM readers) AS total_readers,
                (SELECT COUNT(*) FROM bibliographic_records) AS total_titles,
                (SELECT COUNT(*) FROM book_copies) AS total_copies,
                (SELECT COALESCE(SUM(fine_amount), 0) FROM borrow_transactions
                 WHERE fine_amount > 0 AND fine_paid = 0) AS unpaid_fines
        `),
        db.query(`
            SELECT borrow_date AS event_date, COUNT(*) AS total
            FROM borrow_transactions
            WHERE borrow_date >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
            GROUP BY borrow_date
            ORDER BY borrow_date ASC
        `, [days - 1]),
        db.query(`
            SELECT return_date AS event_date, COUNT(*) AS total
            FROM borrow_transactions
            WHERE return_date IS NOT NULL
              AND return_date >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
            GROUP BY return_date
            ORDER BY return_date ASC
        `, [days - 1]),
        db.query(`
            SELECT b.bib_id, b.subject_headings, COUNT(c.copy_id) AS copy_count
            FROM bibliographic_records b
            LEFT JOIN book_copies c ON c.bib_id = b.bib_id
            GROUP BY b.bib_id, b.subject_headings
        `),
        db.query(`
            SELECT br.bib_id, br.title, COUNT(bt.tx_id) AS borrow_count
            FROM borrow_transactions bt
            JOIN book_copies bc ON bc.copy_id = bt.copy_id
            JOIN bibliographic_records br ON br.bib_id = bc.bib_id
            GROUP BY br.bib_id, br.title
            ORDER BY borrow_count DESC, br.title ASC
            LIMIT 5
        `),
        db.query(`
            SELECT r.reader_id, r.full_name, r.reader_code,
                   COUNT(bt.tx_id) AS borrow_count
            FROM borrow_transactions bt
            JOIN readers r ON r.reader_id = bt.reader_id
            GROUP BY r.reader_id, r.full_name, r.reader_code
            ORDER BY borrow_count DESC, r.full_name ASC
            LIMIT 5
        `)
    ]);

    const borrowedByDate = new Map(
        borrowRows.map((row) => [normalizeDate(row.event_date), Number(row.total)])
    );
    const returnedByDate = new Map(
        returnRows.map((row) => [normalizeDate(row.event_date), Number(row.total)])
    );
    const trend = [];
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    for (let offset = days - 1; offset >= 0; offset -= 1) {
        const date = new Date(today);
        date.setDate(today.getDate() - offset);
        const key = dateKey(date);
        trend.push({
            date: key,
            borrowed: borrowedByDate.get(key) || 0,
            returned: returnedByDate.get(key) || 0
        });
    }

    const categoryMap = new Map();
    for (const row of catalogRows) {
        const subjects = parseJSON(row.subject_headings);
        const name = Array.isArray(subjects) && subjects.length > 0
            ? String(subjects[0]).trim()
            : 'Chưa phân loại';
        const current = categoryMap.get(name) || { title_count: 0, copy_count: 0 };
        current.title_count += 1;
        current.copy_count += Number(row.copy_count) || 0;
        categoryMap.set(name, current);
    }

    const categories = [...categoryMap.entries()]
        .map(([name, value]) => ({ name, ...value }))
        .sort((a, b) => b.title_count - a.title_count || a.name.localeCompare(b.name))
        .slice(0, 6);

    const summary = summaryRows[0] || {};
    return {
        period_days: days,
        summary: {
            active_loans: Number(summary.active_loans) || 0,
            overdue_loans: Number(summary.overdue_loans) || 0,
            total_readers: Number(summary.total_readers) || 0,
            total_titles: Number(summary.total_titles) || 0,
            total_copies: Number(summary.total_copies) || 0,
            unpaid_fines: Number(summary.unpaid_fines) || 0
        },
        loan_trend: trend,
        categories,
        top_books: topBooksRows.map((row) => ({
            bib_id: row.bib_id,
            title: row.title,
            borrow_count: Number(row.borrow_count) || 0
        })),
        top_readers: topReadersRows.map((row) => ({
            reader_id: row.reader_id,
            full_name: row.full_name,
            reader_code: row.reader_code,
            borrow_count: Number(row.borrow_count) || 0
        }))
    };
};
