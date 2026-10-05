SET NAMES utf8mb4;
START TRANSACTION;

-- Mật khẩu mẫu:
-- admin / Admin@123
-- librarian / Librarian@123
-- reader.an / Reader@123
-- reader.minh / Reader@123
INSERT IGNORE INTO users
    (user_id, username, email, full_name, phone, password_hash, role, is_active)
VALUES
    ('00000000-0000-4000-8000-000000000001', 'admin', 'admin@library.local', 'Quản trị viên', '0900000001', '$2a$10$e6eDovwkN2CAWCXwDG6qiu9nK8zq54Ap6UnDeY1qD6ovTfoi52rZq', 'admin', 1),
    ('00000000-0000-4000-8000-000000000002', 'librarian', 'librarian@library.local', 'Thủ thư Demo', '0900000002', '$2a$10$FgWEN.m/zFld/iQxUoUYpOZCX4cIMCNUjmR7u6OGg9J4MiX0sI/sm', 'librarian', 1),
    ('00000000-0000-4000-8000-000000000003', 'reader.an', 'an@library.local', 'Trần Ngọc An', '0900000003', '$2a$10$8hq/ofqdmuFVaKRaYS7KmuMDso.jlMpGWDrs4jG/JF/1I/t5W/d7y', 'reader', 1),
    ('00000000-0000-4000-8000-000000000004', 'reader.minh', 'minh@library.local', 'Nguyễn Minh', '0900000004', '$2a$10$8hq/ofqdmuFVaKRaYS7KmuMDso.jlMpGWDrs4jG/JF/1I/t5W/d7y', 'reader', 1);

INSERT IGNORE INTO readers
    (reader_id, user_id, reader_code, full_name, birth_date, phone, email, address, reader_type, faculty, card_issued, card_expired, status, max_books)
VALUES
    ('10000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000003', 'LIB-DEMO-0001', 'Trần Ngọc An', '2004-07-27', '0900000003', 'an@library.local', '27 Trần Văn Phú, Hà Nội', 'student', 'Công nghệ thông tin', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR), 'active', 5),
    ('10000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000004', 'LIB-DEMO-0002', 'Nguyễn Minh', '2003-05-12', '0900000004', 'minh@library.local', '15 Nguyễn Trãi, Hà Nội', 'student', 'Kinh tế', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 6 MONTH), 'active', 4);

INSERT IGNORE INTO reader_preferences
    (reader_id, preferred_subjects, preferred_authors, preferred_langs, reading_pace, notification_pref)
VALUES
    ('10000000-0000-4000-8000-000000000001', JSON_ARRAY('Công nghệ thông tin', 'Toán học'), JSON_ARRAY('Robert C. Martin'), JSON_ARRAY('vi', 'en'), 'medium', JSON_OBJECT('app', true, 'email', false, 'sms', false)),
    ('10000000-0000-4000-8000-000000000002', JSON_ARRAY('Kinh tế', 'Văn học'), JSON_ARRAY('Tô Hoài'), JSON_ARRAY('vi'), 'slow', JSON_OBJECT('app', true, 'email', false, 'sms', false));

INSERT IGNORE INTO publishers (publisher_id, name, address, contact_email) VALUES
    ('20000000-0000-4000-8000-000000000001', 'Nhà xuất bản Giáo dục Việt Nam', 'Hà Nội', 'contact@giaoduc.vn'),
    ('20000000-0000-4000-8000-000000000002', 'Nhà xuất bản Trẻ', 'TP. Hồ Chí Minh', 'contact@nxbtre.com.vn'),
    ('20000000-0000-4000-8000-000000000003', 'Nhà xuất bản Thông tin và Truyền thông', 'Hà Nội', 'contact@mic.gov.vn');

INSERT IGNORE INTO categories (category_id, category_name, ddc_code, description) VALUES
    ('30000000-0000-4000-8000-000000000001', 'Công nghệ thông tin', '004-006', 'Lập trình, cơ sở dữ liệu, mạng máy tính và trí tuệ nhân tạo'),
    ('30000000-0000-4000-8000-000000000002', 'Toán học', '510', 'Giáo trình và tài liệu toán học'),
    ('30000000-0000-4000-8000-000000000003', 'Văn học', '800', 'Văn học Việt Nam và thế giới'),
    ('30000000-0000-4000-8000-000000000004', 'Kinh tế', '330', 'Kinh tế học và quản trị'),
    ('30000000-0000-4000-8000-000000000005', 'Khoa học xã hội', '300', 'Tài liệu khoa học xã hội');

INSERT IGNORE INTO shelf_locations (location_id, floor, section, shelf, position, capacity, ddc_range) VALUES
    ('40000000-0000-4000-8000-000000000001', 1, 'A', 'A01', '01', 100, '000-099'),
    ('40000000-0000-4000-8000-000000000002', 1, 'B', 'B01', '01', 100, '300-399'),
    ('40000000-0000-4000-8000-000000000003', 2, 'C', 'C01', '01', 100, '500-599'),
    ('40000000-0000-4000-8000-000000000004', 2, 'D', 'D01', '01', 100, '800-899');

INSERT IGNORE INTO bibliographic_records
    (bib_id, isbn, title, subtitle, authors, publisher_id, publish_year, edition, language, description, page_count, call_number, ddc_class, subject_headings, keywords, metadata)
VALUES
    ('50000000-0000-4000-8000-000000000001', '9780132350884', 'Clean Code', 'A Handbook of Agile Software Craftsmanship', JSON_ARRAY(JSON_OBJECT('name', 'Robert C. Martin', 'role', 'author')), '20000000-0000-4000-8000-000000000003', 2008, '1', 'en', 'Nguyên tắc và kỹ thuật viết mã nguồn sạch, dễ bảo trì.', 464, '005.1 MAR', '005.1', JSON_ARRAY('Lập trình', 'Kỹ nghệ phần mềm'), JSON_ARRAY('clean code', 'refactoring'), JSON_OBJECT('source', 'demo')),
    ('50000000-0000-4000-8000-000000000002', '9780134685991', 'Effective Java', 'Best Practices for the Java Platform', JSON_ARRAY(JSON_OBJECT('name', 'Joshua Bloch', 'role', 'author')), '20000000-0000-4000-8000-000000000003', 2018, '3', 'en', 'Các thực hành tốt để xây dựng phần mềm Java hiệu quả.', 416, '005.133 BLO', '005.133', JSON_ARRAY('Java', 'Lập trình'), JSON_ARRAY('java', 'best practices'), JSON_OBJECT('source', 'demo')),
    ('50000000-0000-4000-8000-000000000003', '9786040000001', 'Giáo trình Cơ sở dữ liệu', NULL, JSON_ARRAY(JSON_OBJECT('name', 'Nguyễn Kim Anh', 'role', 'author')), '20000000-0000-4000-8000-000000000001', 2022, '2', 'vi', 'Kiến thức nền tảng về mô hình dữ liệu, SQL và thiết kế cơ sở dữ liệu.', 320, '005.74 NGU', '005.74', JSON_ARRAY('Cơ sở dữ liệu', 'SQL'), JSON_ARRAY('mysql', 'database', 'sql'), JSON_OBJECT('source', 'demo')),
    ('50000000-0000-4000-8000-000000000004', '9786040000002', 'Mạng máy tính', 'Từ cơ bản đến nâng cao', JSON_ARRAY(JSON_OBJECT('name', 'Trần Văn Thành', 'role', 'author')), '20000000-0000-4000-8000-000000000003', 2021, '1', 'vi', 'Giới thiệu kiến trúc mạng, TCP/IP và bảo mật mạng.', 380, '004.6 TRA', '004.6', JSON_ARRAY('Mạng máy tính', 'Bảo mật'), JSON_ARRAY('network', 'tcp/ip'), JSON_OBJECT('source', 'demo')),
    ('50000000-0000-4000-8000-000000000005', '9786040000003', 'Giáo trình Toán cao cấp', NULL, JSON_ARRAY(JSON_OBJECT('name', 'Lê Trọng Lang', 'role', 'author')), '20000000-0000-4000-8000-000000000001', 2023, '1', 'vi', 'Giáo trình giải tích và đại số dành cho sinh viên.', 420, '515 LE', '515', JSON_ARRAY('Toán học', 'Giải tích'), JSON_ARRAY('toán cao cấp', 'giải tích'), JSON_OBJECT('source', 'demo')),
    ('50000000-0000-4000-8000-000000000006', '9786040000004', 'Dế Mèn phiêu lưu ký', NULL, JSON_ARRAY(JSON_OBJECT('name', 'Tô Hoài', 'role', 'author')), '20000000-0000-4000-8000-000000000002', 2020, 'Tái bản', 'vi', 'Tác phẩm văn học thiếu nhi kinh điển của Việt Nam.', 192, '895.922 TO', '895.922', JSON_ARRAY('Văn học Việt Nam', 'Thiếu nhi'), JSON_ARRAY('dế mèn', 'tô hoài'), JSON_OBJECT('source', 'demo')),
    ('50000000-0000-4000-8000-000000000007', '9786040000005', 'Kinh tế học vi mô', NULL, JSON_ARRAY(JSON_OBJECT('name', 'Nguyễn Văn Công', 'role', 'author')), '20000000-0000-4000-8000-000000000001', 2022, '3', 'vi', 'Nhập môn kinh tế học vi mô dành cho sinh viên.', 360, '338.5 NGU', '338.5', JSON_ARRAY('Kinh tế học', 'Vi mô'), JSON_ARRAY('kinh tế', 'vi mô'), JSON_OBJECT('source', 'demo')),
    ('50000000-0000-4000-8000-000000000008', '9786040000006', 'Nhập môn Trí tuệ nhân tạo', NULL, JSON_ARRAY(JSON_OBJECT('name', 'Phạm Minh Tuấn', 'role', 'author')), '20000000-0000-4000-8000-000000000003', 2024, '1', 'vi', 'Tổng quan về tìm kiếm, học máy và các hệ thống thông minh.', 410, '006.3 PHA', '006.3', JSON_ARRAY('Trí tuệ nhân tạo', 'Học máy'), JSON_ARRAY('ai', 'machine learning'), JSON_OBJECT('source', 'demo'));

INSERT IGNORE INTO book_copies
    (copy_id, bib_id, barcode, `condition`, location_id, status, acquired_date, acquired_price)
VALUES
    ('60000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000001', 'LIB-CC-0001', 'good', '40000000-0000-4000-8000-000000000001', 'available', CURDATE(), 250000),
    ('60000000-0000-4000-8000-000000000002', '50000000-0000-4000-8000-000000000001', 'LIB-CC-0002', 'good', '40000000-0000-4000-8000-000000000001', 'borrowed', CURDATE(), 250000),
    ('60000000-0000-4000-8000-000000000003', '50000000-0000-4000-8000-000000000002', 'LIB-EJ-0001', 'new', '40000000-0000-4000-8000-000000000001', 'available', CURDATE(), 300000),
    ('60000000-0000-4000-8000-000000000004', '50000000-0000-4000-8000-000000000003', 'LIB-DB-0001', 'fair', '40000000-0000-4000-8000-000000000001', 'borrowed', CURDATE(), 150000),
    ('60000000-0000-4000-8000-000000000005', '50000000-0000-4000-8000-000000000003', 'LIB-DB-0002', 'good', '40000000-0000-4000-8000-000000000001', 'available', CURDATE(), 150000),
    ('60000000-0000-4000-8000-000000000006', '50000000-0000-4000-8000-000000000004', 'LIB-NET-0001', 'good', '40000000-0000-4000-8000-000000000001', 'available', CURDATE(), 180000),
    ('60000000-0000-4000-8000-000000000007', '50000000-0000-4000-8000-000000000005', 'LIB-MATH-0001', 'good', '40000000-0000-4000-8000-000000000003', 'reserved', CURDATE(), 120000),
    ('60000000-0000-4000-8000-000000000008', '50000000-0000-4000-8000-000000000006', 'LIB-DM-0001', 'good', '40000000-0000-4000-8000-000000000004', 'available', CURDATE(), 90000),
    ('60000000-0000-4000-8000-000000000009', '50000000-0000-4000-8000-000000000007', 'LIB-ECO-0001', 'good', '40000000-0000-4000-8000-000000000002', 'available', CURDATE(), 160000),
    ('60000000-0000-4000-8000-000000000010', '50000000-0000-4000-8000-000000000008', 'LIB-AI-0001', 'new', '40000000-0000-4000-8000-000000000001', 'available', CURDATE(), 220000),
    ('60000000-0000-4000-8000-000000000011', '50000000-0000-4000-8000-000000000008', 'LIB-AI-0002', 'good', '40000000-0000-4000-8000-000000000001', 'available', CURDATE(), 220000);

INSERT IGNORE INTO borrow_transactions
    (tx_id, reader_id, copy_id, borrow_date, due_date, return_date, status, fine_amount, fine_paid, issued_by, returned_to)
VALUES
    ('70000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', DATE_SUB(CURDATE(), INTERVAL 30 DAY), DATE_SUB(CURDATE(), INTERVAL 16 DAY), DATE_SUB(CURDATE(), INTERVAL 18 DAY), 'returned', 0, 1, '00000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000002'),
    ('70000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000002', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY), NULL, 'borrowed', 0, 0, '00000000-0000-4000-8000-000000000002', NULL),
    ('70000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002', '60000000-0000-4000-8000-000000000004', DATE_SUB(CURDATE(), INTERVAL 20 DAY), DATE_SUB(CURDATE(), INTERVAL 6 DAY), NULL, 'overdue', 12000, 0, '00000000-0000-4000-8000-000000000002', NULL);

INSERT IGNORE INTO renewal_requests
    (request_id, tx_id, reader_id, requested_days, status)
VALUES
    ('80000000-0000-4000-8000-000000000001', '70000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 5, 'pending');

INSERT IGNORE INTO holds
    (hold_id, reader_id, bib_id, requested_at, notified_at, expires_at, status, queue_position)
VALUES
    ('90000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', '50000000-0000-4000-8000-000000000005', DATE_SUB(NOW(), INTERVAL 1 DAY), NOW(), DATE_ADD(NOW(), INTERVAL 3 DAY), 'notified', NULL);

INSERT IGNORE INTO notifications
    (notification_id, reader_id, title, content, type, reference_id, is_read)
VALUES
    ('a0000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'Phiếu mượn đã được tạo', 'Bạn đã mượn sách Clean Code thành công.', 'system', '70000000-0000-4000-8000-000000000002', 1),
    ('a0000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 'Sách đặt trước đã sẵn sàng', 'Giáo trình Toán cao cấp đã được giữ tại quầy trong 3 ngày.', 'hold_available', '90000000-0000-4000-8000-000000000001', 0),
    ('a0000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002', 'Sách đang quá hạn', 'Giáo trình Cơ sở dữ liệu đã quá hạn trả.', 'overdue', '70000000-0000-4000-8000-000000000003', 0);

INSERT IGNORE INTO chat_messages
    (message_id, reader_id, sender_id, sender_role, message_text, is_read)
VALUES
    ('b0000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000003', 'reader', 'Em muốn hỏi về thời hạn gia hạn sách.', 0),
    ('b0000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000002', 'librarian', 'Bạn có thể gửi yêu cầu gia hạn tối đa 7 ngày trên ứng dụng.', 0);

COMMIT;
