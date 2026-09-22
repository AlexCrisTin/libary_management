const db = require('../../config/db');
const { v4: uuidv4 } = require('uuid');

/**
 * 1. Lấy danh sách toàn bộ các vị trí kệ sách (Kèm số lượng hiện có, sức chứa và trạng thái đầy)
 */
exports.getAllShelves = async () => {
    const sql = `
        SELECT 
            s.location_id,
            s.floor,
            s.section,
            s.shelf,
            s.position,
            s.capacity,
            s.ddc_range,
            COUNT(c.copy_id) AS current_books_count,
            GREATEST(0, s.capacity - COUNT(c.copy_id)) AS remaining_capacity,
            CASE WHEN COUNT(c.copy_id) >= s.capacity THEN 1 ELSE 0 END AS is_full
        FROM shelf_locations s
        LEFT JOIN book_copies c ON s.location_id = c.location_id
        GROUP BY s.location_id
        ORDER BY s.floor ASC, s.section ASC, s.shelf ASC, s.position ASC
    `;
    const [rows] = await db.query(sql);
    return rows.map(row => ({
        ...row,
        current_books_count: Number(row.current_books_count) || 0,
        remaining_capacity: Number(row.remaining_capacity) || 0,
        is_full: Boolean(row.is_full)
    }));
};

/**
 * 2. Lấy thông tin chi tiết một kệ sách
 */
exports.getShelfById = async (locationId) => {
    const sql = `
        SELECT 
            s.*,
            COUNT(c.copy_id) AS current_books_count,
            GREATEST(0, s.capacity - COUNT(c.copy_id)) AS remaining_capacity,
            CASE WHEN COUNT(c.copy_id) >= s.capacity THEN 1 ELSE 0 END AS is_full
        FROM shelf_locations s
        LEFT JOIN book_copies c ON s.location_id = c.location_id
        WHERE s.location_id = ?
        GROUP BY s.location_id
    `;
    const [rows] = await db.query(sql, [locationId]);
    if (rows.length === 0) return null;

    const row = rows[0];
    return {
        ...row,
        current_books_count: Number(row.current_books_count) || 0,
        remaining_capacity: Number(row.remaining_capacity) || 0,
        is_full: Boolean(row.is_full)
    };
};

/**
 * 3. Lấy danh sách các cuốn sách đang nằm trên một kệ cụ thể
 */
exports.getBooksOnShelf = async (locationId) => {
    const sql = `
        SELECT 
            c.copy_id,
            c.barcode,
            c.condition,
            c.status,
            b.bib_id,
            b.title,
            b.isbn,
            b.authors,
            b.call_number
        FROM book_copies c
        JOIN bibliographic_records b ON c.bib_id = b.bib_id
        WHERE c.location_id = ?
        ORDER BY c.barcode ASC
    `;
    const [rows] = await db.query(sql, [locationId]);
    return rows;
};

/**
 * 4. Tạo mới một vị trí kệ sách (Hỗ trợ cấu hình sức chứa tối đa capacity)
 */
exports.createShelf = async ({ floor, section, shelf, position = null, capacity = 50, ddc_range = null }) => {
    const locationId = uuidv4();
    const finalCapacity = Number(capacity) > 0 ? Number(capacity) : 50;

    const sql = `
        INSERT INTO shelf_locations (location_id, floor, section, shelf, position, capacity, ddc_range)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    `;
    await db.query(sql, [locationId, floor, section, shelf, position, finalCapacity, ddc_range]);

    return {
        location_id: locationId,
        floor,
        section,
        shelf,
        position,
        capacity: finalCapacity,
        ddc_range
    };
};

/**
 * 5. Cập nhật thông tin kệ sách (Có thể tăng/giảm sức chứa capacity)
 */
exports.updateShelf = async (locationId, updateData) => {
    const fields = [];
    const values = [];

    const allowed = ['floor', 'section', 'shelf', 'position', 'capacity', 'ddc_range'];
    allowed.forEach((col) => {
        if (updateData[col] !== undefined) {
            fields.push(`${col} = ?`);
            values.push(col === 'capacity' ? Number(updateData[col]) : updateData[col]);
        }
    });

    if (fields.length === 0) return false;

    values.push(locationId);
    const sql = `UPDATE shelf_locations SET ${fields.join(', ')} WHERE location_id = ?`;
    const [result] = await db.query(sql, values);
    return result.affectedRows > 0;
};

/**
 * 6. Xóa kệ sách
 */
exports.deleteShelf = async (locationId) => {
    // Gỡ các sách trên kệ về trạng thái chưa xếp kệ (NULL)
    await db.query('UPDATE book_copies SET location_id = NULL WHERE location_id = ?', [locationId]);

    const [result] = await db.query('DELETE FROM shelf_locations WHERE location_id = ?', [locationId]);
    return result.affectedRows > 0;
};

/**
 * 7. Xếp sách vào kệ / Chuyển kệ / Loại khỏi kệ
 * - Hỗ trợ truyền barcode, copy_id, HOẶC bib_id (để xếp toàn bộ bản sao của đầu sách)
 * - TỰ ĐỘNG KIỂM TRA SỨC CHỨA (CAPACITY): Nếu kệ đầy sẽ báo lỗi chặn lại ngay!
 */
exports.assignBookToShelf = async ({ copy_id, barcode, bib_id, location_id }) => {
    let targetCopies = [];

    // 1. Tìm các bản sao cần xếp kệ
    if (copy_id) {
        const [rows] = await db.query('SELECT * FROM book_copies WHERE copy_id = ?', [copy_id]);
        if (rows.length > 0) targetCopies.push(rows[0]);
    } else if (barcode) {
        const [rows] = await db.query('SELECT * FROM book_copies WHERE barcode = ?', [barcode]);
        if (rows.length > 0) targetCopies.push(rows[0]);
    } else if (bib_id) {
        // Lấy tất cả các bản sao của đầu sách này
        const [rows] = await db.query('SELECT * FROM book_copies WHERE bib_id = ?', [bib_id]);
        targetCopies = rows;
    }

    if (targetCopies.length === 0) {
        throw new Error('Không tìm thấy bản sao sách nào với thông tin cung cấp (copy_id, barcode hoặc bib_id)!');
    }

    // 2. Nếu gán vào một kệ cụ thể (location_id khác null) -> Kiểm tra sức chứa
    let targetShelf = null;
    if (location_id) {
        const [shelfRows] = await db.query(
            `SELECT s.*, COUNT(c.copy_id) AS current_count 
             FROM shelf_locations s 
             LEFT JOIN book_copies c ON s.location_id = c.location_id 
             WHERE s.location_id = ? 
             GROUP BY s.location_id`,
            [location_id]
        );

        if (shelfRows.length === 0) {
            throw new Error('Kệ sách đích không tồn tại!');
        }

        targetShelf = shelfRows[0];
        const currentCount = Number(targetShelf.current_count) || 0;
        const capacity = Number(targetShelf.capacity) || 50;

        // Đếm số lượng sách thực tế sẽ được thêm mới vào kệ này (bỏ qua những cuốn vốn đã nằm sẵn trên kệ đó)
        const newAddCount = targetCopies.filter(copy => copy.location_id !== location_id).length;

        if (currentCount + newAddCount > capacity) {
            throw new Error(
                `Kệ sách đã đầy hoặc không đủ chỗ! (Hiện tại: ${currentCount}/${capacity} cuốn, muốn thêm: ${newAddCount} cuốn, còn trống: ${Math.max(0, capacity - currentCount)} cuốn). Vui lòng chọn kệ khác!`
            );
        }
    }

    // 3. Tiến hành cập nhật vị trí kệ
    const copyIds = targetCopies.map(c => c.copy_id);
    const placeholders = copyIds.map(() => '?').join(', ');
    const updateSql = `UPDATE book_copies SET location_id = ? WHERE copy_id IN (${placeholders})`;
    await db.query(updateSql, [location_id || null, ...copyIds]);

    const shelfName = targetShelf 
        ? `Kệ Tầng ${targetShelf.floor} - Khu ${targetShelf.section} - Kệ ${targetShelf.shelf} (Sức chứa: ${targetShelf.capacity} cuốn)`
        : 'được loại khỏi kệ';

    return {
        affected_copies_count: copyIds.length,
        copies: targetCopies.map(c => ({ copy_id: c.copy_id, barcode: c.barcode })),
        new_location_id: location_id || null,
        status_message: location_id 
            ? `Đã xếp ${copyIds.length} cuốn sách vào ${shelfName} thành công!`
            : `Đã loại ${copyIds.length} cuốn sách khỏi kệ thành công!`
    };
};
