-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 25, 2026 at 02:55 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `library_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `bibliographic_records`
--

CREATE TABLE `bibliographic_records` (
  `bib_id` varchar(36) NOT NULL,
  `isbn` varchar(20) DEFAULT NULL,
  `title` varchar(500) NOT NULL,
  `subtitle` varchar(500) DEFAULT NULL,
  `authors` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '[{"name": "Robert C. Martin", "role": "author"}]' CHECK (json_valid(`authors`)),
  `publisher_id` varchar(36) DEFAULT NULL,
  `publish_year` smallint(6) DEFAULT NULL,
  `edition` varchar(50) DEFAULT NULL,
  `language` varchar(10) DEFAULT 'vi',
  `description` text DEFAULT NULL COMMENT 'Tóm tắt nội dung sách',
  `page_count` int(11) DEFAULT NULL,
  `call_number` varchar(50) DEFAULT NULL COMMENT 'Mã xếp giá DDC: 005.133',
  `ddc_class` varchar(20) DEFAULT NULL COMMENT 'Phân loại môn loại Dewey',
  `subject_headings` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Mảng chủ đề: ["Lập trình", "Clean Code"]' CHECK (json_valid(`subject_headings`)),
  `keywords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Mảng từ khóa tìm kiếm: ["software", "refactoring"]' CHECK (json_valid(`keywords`)),
  `cover_url` text DEFAULT NULL COMMENT 'Đường dẫn ảnh bìa sách',
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Thông tin bổ sung: size, weight, series...' CHECK (json_valid(`metadata`)),
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `bibliographic_records`
--

INSERT INTO `bibliographic_records` (`bib_id`, `isbn`, `title`, `subtitle`, `authors`, `publisher_id`, `publish_year`, `edition`, `language`, `description`, `page_count`, `call_number`, `ddc_class`, `subject_headings`, `keywords`, `cover_url`, `metadata`, `created_at`) VALUES
('538450b3-3716-4e3c-8049-de42c55abc23', '978-604-09999', 'Thiết kế Hướng đối tượng nâng cao', NULL, '[{\"name\":\"Erich Gamma\",\"role\":\"author\"}]', NULL, 2024, NULL, 'vi', 'Giáo trình Design Patterns và lập trình hướng đối tượng.', NULL, NULL, NULL, '[]', '[]', NULL, '{}', '2026-09-24 20:04:49'),
('88cc3751-a92b-431a-91e0-3a03066cf96a', '978-604-0123', 'Lập trình Flutter Pro 2026 (Đã cập nhật)', NULL, '[{\"name\":\"Nguyễn Văn A\",\"role\":\"author\"}]', NULL, 2026, NULL, 'vi', 'Tài liệu tái bản mới nhất có bổ sung kiến thức AI', NULL, NULL, NULL, '[]', '[]', NULL, '{}', '2026-09-11 15:42:49');

-- --------------------------------------------------------

--
-- Table structure for table `book_copies`
--

CREATE TABLE `book_copies` (
  `copy_id` varchar(36) NOT NULL,
  `bib_id` varchar(36) NOT NULL,
  `barcode` varchar(50) NOT NULL COMMENT 'Mã vạch dán trên gáy sách vật lý',
  `condition` enum('new','good','fair','poor','damaged') DEFAULT 'good',
  `location_id` varchar(36) DEFAULT NULL,
  `status` enum('available','borrowed','reserved','lost','processing') DEFAULT 'available',
  `acquired_date` date DEFAULT NULL,
  `acquired_price` decimal(12,2) DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `book_copies`
--

INSERT INTO `book_copies` (`copy_id`, `bib_id`, `barcode`, `condition`, `location_id`, `status`, `acquired_date`, `acquired_price`) VALUES
('1d33d4f4-b40c-4013-8b07-d2ddd17d91a7', '88cc3751-a92b-431a-91e0-3a03066cf96a', 'BC-169661-03', 'good', 'b941abbf-089c-4dc6-b9bd-0547b0d06b96', 'available', '2026-09-11', 0.00),
('2ed45c21-7fb6-4c34-b3be-3d791ab20cca', '88cc3751-a92b-431a-91e0-3a03066cf96a', 'BC-169656-02', 'good', 'b941abbf-089c-4dc6-b9bd-0547b0d06b96', 'available', '2026-09-11', 0.00),
('852c3384-a284-464c-ae1e-1d2d9954f6e3', '88cc3751-a92b-431a-91e0-3a03066cf96a', 'BC-169641-01', 'good', 'b941abbf-089c-4dc6-b9bd-0547b0d06b96', 'available', '2026-09-11', 0.00),
('9a609aa5-5e90-42fd-b433-7edaa626fd99', '538450b3-3716-4e3c-8049-de42c55abc23', 'BC-089066-01', 'good', '7fb9864d-019b-45c9-967a-b2c0b9f0b843', 'borrowed', '2026-09-24', 0.00);

-- --------------------------------------------------------

--
-- Table structure for table `borrow_transactions`
--

CREATE TABLE `borrow_transactions` (
  `tx_id` varchar(36) NOT NULL,
  `reader_id` varchar(36) NOT NULL,
  `copy_id` varchar(36) NOT NULL,
  `borrow_date` date NOT NULL,
  `due_date` date NOT NULL,
  `return_date` date DEFAULT NULL COMMENT 'NULL nghĩa là chưa trả',
  `renewed_count` smallint(6) DEFAULT 0,
  `status` enum('borrowed','returned','overdue','lost') DEFAULT 'borrowed',
  `fine_amount` decimal(10,2) DEFAULT 0.00,
  `fine_paid` tinyint(1) DEFAULT 0,
  `issued_by` varchar(36) DEFAULT NULL COMMENT 'Thủ thư cho mượn',
  `returned_to` varchar(36) DEFAULT NULL COMMENT 'Thủ thư nhận trả',
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `borrow_transactions`
--

INSERT INTO `borrow_transactions` (`tx_id`, `reader_id`, `copy_id`, `borrow_date`, `due_date`, `return_date`, `renewed_count`, `status`, `fine_amount`, `fine_paid`, `issued_by`, `returned_to`, `created_at`) VALUES
('06ed4e9b-3beb-4cfe-8553-9bcb2494c4bb', '6e4bd7c5-2f45-4242-8c15-79da2b71ca14', '852c3384-a284-464c-ae1e-1d2d9954f6e3', '2026-09-17', '2026-10-01', '2026-09-17', 0, 'returned', 0.00, 0, '7213e204-b28f-11f1-9923-6018953bc19c', '7213e204-b28f-11f1-9923-6018953bc19c', '2026-09-17 19:15:57'),
('585bef7e-4873-43b5-a14a-358ff3f12258', '6e4bd7c5-2f45-4242-8c15-79da2b71ca14', '9a609aa5-5e90-42fd-b433-7edaa626fd99', '2026-09-24', '2026-10-08', NULL, 0, 'borrowed', 0.00, 0, '7213e204-b28f-11f1-9923-6018953bc19c', NULL, '2026-09-24 20:15:17');

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `category_id` varchar(36) NOT NULL,
  `category_name` varchar(100) NOT NULL COMMENT 'Tên thể loại: Tin học, Kinh tế...',
  `ddc_code` varchar(20) DEFAULT NULL COMMENT 'Mã phân loại Dewey: 004, 330...',
  `description` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `chat_messages`
--

CREATE TABLE `chat_messages` (
  `message_id` varchar(36) NOT NULL,
  `reader_id` varchar(36) NOT NULL COMMENT 'Kênh chat thuộc về độc giả nào',
  `sender_id` varchar(36) NOT NULL COMMENT 'user_id của người gửi (độc giả hoặc thủ thư)',
  `sender_role` enum('reader','librarian') NOT NULL COMMENT 'Vai trò của người gửi lúc nhắn',
  `message_text` text NOT NULL COMMENT 'Nội dung tin nhắn',
  `is_read` tinyint(1) DEFAULT 0 COMMENT 'Đối phương đã xem tin nhắn hay chưa',
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `holds`
--

CREATE TABLE `holds` (
  `hold_id` varchar(36) NOT NULL,
  `reader_id` varchar(36) NOT NULL,
  `bib_id` varchar(36) NOT NULL COMMENT 'Đặt theo đầu sách',
  `requested_at` datetime DEFAULT current_timestamp(),
  `notified_at` datetime DEFAULT NULL COMMENT 'Thời điểm báo có sách',
  `expires_at` datetime DEFAULT NULL COMMENT 'Hạn giữ sách',
  `status` enum('waiting','notified','fulfilled','cancelled','expired') DEFAULT 'waiting',
  `queue_position` int(11) DEFAULT 1 COMMENT 'Thứ tự trong hàng chờ'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `holds`
--

INSERT INTO `holds` (`hold_id`, `reader_id`, `bib_id`, `requested_at`, `notified_at`, `expires_at`, `status`, `queue_position`) VALUES
('9a945b17-77a9-4cd5-bf69-94988a78ddfe', '2fd98a5b-d96b-4f68-8423-7b63c87ed133', '538450b3-3716-4e3c-8049-de42c55abc23', '2026-09-24 20:23:35', NULL, NULL, 'waiting', 1),
('cf376c61-f4f8-44a3-88cb-41b71bcf0128', '32cb4aad-7655-4334-a65b-2545eac8adde', '538450b3-3716-4e3c-8049-de42c55abc23', '2026-09-24 20:24:49', NULL, NULL, 'waiting', 2);

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `notification_id` varchar(36) NOT NULL,
  `reader_id` varchar(36) NOT NULL COMMENT 'Độc giả nhận thông báo',
  `title` varchar(255) NOT NULL COMMENT 'Tiêu đề thông báo',
  `content` text NOT NULL COMMENT 'Nội dung chi tiết',
  `type` enum('hold_available','due_soon','overdue','card_expired','system') DEFAULT 'system' COMMENT 'Phân loại thông báo',
  `reference_id` varchar(36) DEFAULT NULL COMMENT 'Mã tham chiếu: hold_id hoặc tx_id để bấm vào xem chi tiết',
  `is_read` tinyint(1) DEFAULT 0 COMMENT '0: Chưa đọc, 1: Đã đọc',
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `publishers`
--

CREATE TABLE `publishers` (
  `publisher_id` varchar(36) NOT NULL,
  `name` varchar(255) NOT NULL,
  `address` text DEFAULT NULL,
  `contact_email` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `readers`
--

CREATE TABLE `readers` (
  `reader_id` varchar(36) NOT NULL,
  `user_id` varchar(36) DEFAULT NULL,
  `reader_code` varchar(20) NOT NULL COMMENT 'VD: LIB-2024-00001',
  `full_name` varchar(200) NOT NULL,
  `birth_date` date DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `reader_type` enum('student','lecturer','staff','public') DEFAULT 'student',
  `faculty` varchar(200) DEFAULT NULL COMMENT 'Khoa nếu là SV/GV',
  `card_issued` date DEFAULT NULL,
  `card_expired` date DEFAULT NULL,
  `status` enum('active','suspended','expired') DEFAULT 'active',
  `max_books` smallint(6) DEFAULT 5,
  `avatar_url` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `readers`
--

INSERT INTO `readers` (`reader_id`, `user_id`, `reader_code`, `full_name`, `birth_date`, `phone`, `email`, `reader_type`, `faculty`, `card_issued`, `card_expired`, `status`, `max_books`, `avatar_url`, `created_at`) VALUES
('2fd98a5b-d96b-4f68-8423-7b63c87ed133', 'da87f3b4-5989-468c-afe5-bdd46de9cdbf', 'RD-767378', 'Test A', NULL, NULL, 'docgia_a@test.com', 'student', 'Công nghệ thông tin', '2026-09-24', '2027-09-24', 'active', 5, NULL, '2026-09-24 20:16:07'),
('32cb4aad-7655-4334-a65b-2545eac8adde', '3700a4d8-85ed-458e-b54a-9a67c5c13ec8', 'RD-809238', 'Test B', NULL, NULL, 'docgia_b@test.com', 'student', 'Toán Tin', '2026-09-24', '2027-09-24', 'active', 5, NULL, '2026-09-24 20:16:49'),
('6e4bd7c5-2f45-4242-8c15-79da2b71ca14', '596ff42c-6dd3-4622-abba-a4d7bdcc6fe1', 'RD-986776', 'Nguyễn Văn B', '2003-10-20', '0901234567', 'vanb@gmail.com', 'student', 'Công nghệ thông tin', '2026-09-15', '2027-09-15', 'active', 5, NULL, '2026-09-15 09:23:06');

-- --------------------------------------------------------

--
-- Table structure for table `reader_preferences`
--

CREATE TABLE `reader_preferences` (
  `reader_id` varchar(36) NOT NULL,
  `preferred_subjects` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Mảng mã chủ đề yêu thích: ["uuid1", "uuid2"]' CHECK (json_valid(`preferred_subjects`)),
  `preferred_authors` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Mảng tác giả: ["Nguyễn Nhật Ánh", "Tô Hoài"]' CHECK (json_valid(`preferred_authors`)),
  `preferred_langs` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Mảng ngôn ngữ: ["vi", "en"]' CHECK (json_valid(`preferred_langs`)),
  `reading_pace` enum('slow','medium','fast') DEFAULT 'medium',
  `notification_pref` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Cấu hình thông báo: {"email": true, "app": true, "sms": false}' CHECK (json_valid(`notification_pref`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `reader_preferences`
--

INSERT INTO `reader_preferences` (`reader_id`, `preferred_subjects`, `preferred_authors`, `preferred_langs`, `reading_pace`, `notification_pref`) VALUES
('2fd98a5b-d96b-4f68-8423-7b63c87ed133', '[]', '[]', '[\"vi\"]', 'medium', '{\"email\": true, \"app\": true, \"sms\": false}'),
('32cb4aad-7655-4334-a65b-2545eac8adde', '[]', '[]', '[\"vi\"]', 'medium', '{\"email\": true, \"app\": true, \"sms\": false}'),
('6e4bd7c5-2f45-4242-8c15-79da2b71ca14', '[\"Công nghệ thông tin\",\"Kỹ năng lập trình\",\"Khoa học\"]', '[\"Robert C. Martin\",\"Martin Fowler\"]', '[\"vi\",\"en\"]', 'fast', '{\"email\":true,\"app\":true,\"sms\":false}');

-- --------------------------------------------------------

--
-- Table structure for table `shelf_locations`
--

CREATE TABLE `shelf_locations` (
  `location_id` varchar(36) NOT NULL,
  `floor` smallint(6) NOT NULL,
  `section` varchar(20) NOT NULL COMMENT 'Khu A, B, C...',
  `shelf` varchar(10) NOT NULL COMMENT 'Kệ số...',
  `position` varchar(10) DEFAULT NULL COMMENT 'Ngăn/Vị trí',
  `capacity` int(11) DEFAULT 50 COMMENT 'Suc chua toi da',
  `ddc_range` varchar(50) DEFAULT NULL COMMENT '000-099 Tin học...'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `shelf_locations`
--

INSERT INTO `shelf_locations` (`location_id`, `floor`, `section`, `shelf`, `position`, `capacity`, `ddc_range`) VALUES
('7fb9864d-019b-45c9-967a-b2c0b9f0b843', 1, 'A', '02', 'Ngăn 1', 20, '100-199 Triết học'),
('b941abbf-089c-4dc6-b9bd-0547b0d06b96', 1, 'A', '01', 'Ngăn 1', 20, '000-099 Tin học');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` varchar(36) NOT NULL,
  `username` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('admin','librarian','reader') NOT NULL DEFAULT 'reader',
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `password_hash`, `role`, `is_active`, `created_at`) VALUES
('3700a4d8-85ed-458e-b54a-9a67c5c13ec8', 'docgia_b', '$2a$10$3Q1ppfAPAvwHpgu52C/62OYJy.dRSnhcXMDy./CDDeBjIdzHfZ6Ly', 'reader', 1, '2026-09-24 20:16:49'),
('596ff42c-6dd3-4622-abba-a4d7bdcc6fe1', 'docgia_nguyenvanb', '$2a$10$oLx6YMGvNPqc87C9QxU.9OI3STaiWN0CSGKGKg1pY73YjLTyZWNVu', 'reader', 1, '2026-09-15 09:23:06'),
('7213e204-b28f-11f1-9923-6018953bc19c', 'admin', '$2a$12$F2coLM/cuo8GBgC9mIwdS.QabWZE3ahUhY5gXhx4eyTKP7dQ2BQKq', 'librarian', 1, '2026-09-17 19:00:58'),
('da87f3b4-5989-468c-afe5-bdd46de9cdbf', 'docgia_a', '$2a$10$KxEgMEU6pYXHSjOfTxzv6ukByt0Q5gRkcOSqZFec8MjmGOQAqYwtC', 'reader', 1, '2026-09-24 20:16:07');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bibliographic_records`
--
ALTER TABLE `bibliographic_records`
  ADD PRIMARY KEY (`bib_id`),
  ADD KEY `fk_bib_publisher` (`publisher_id`);

--
-- Indexes for table `book_copies`
--
ALTER TABLE `book_copies`
  ADD PRIMARY KEY (`copy_id`),
  ADD UNIQUE KEY `barcode` (`barcode`),
  ADD KEY `fk_copy_bib` (`bib_id`),
  ADD KEY `fk_copy_location` (`location_id`);

--
-- Indexes for table `borrow_transactions`
--
ALTER TABLE `borrow_transactions`
  ADD PRIMARY KEY (`tx_id`),
  ADD KEY `fk_tx_reader` (`reader_id`),
  ADD KEY `fk_tx_copy` (`copy_id`),
  ADD KEY `fk_tx_issuer` (`issued_by`),
  ADD KEY `fk_tx_receiver` (`returned_to`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`category_id`),
  ADD UNIQUE KEY `category_name` (`category_name`);

--
-- Indexes for table `chat_messages`
--
ALTER TABLE `chat_messages`
  ADD PRIMARY KEY (`message_id`),
  ADD KEY `fk_chat_reader` (`reader_id`),
  ADD KEY `fk_chat_sender` (`sender_id`);

--
-- Indexes for table `holds`
--
ALTER TABLE `holds`
  ADD PRIMARY KEY (`hold_id`),
  ADD KEY `fk_hold_reader` (`reader_id`),
  ADD KEY `fk_hold_bib` (`bib_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `fk_notif_reader` (`reader_id`);

--
-- Indexes for table `publishers`
--
ALTER TABLE `publishers`
  ADD PRIMARY KEY (`publisher_id`);

--
-- Indexes for table `readers`
--
ALTER TABLE `readers`
  ADD PRIMARY KEY (`reader_id`),
  ADD UNIQUE KEY `reader_code` (`reader_code`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Indexes for table `reader_preferences`
--
ALTER TABLE `reader_preferences`
  ADD PRIMARY KEY (`reader_id`);

--
-- Indexes for table `shelf_locations`
--
ALTER TABLE `shelf_locations`
  ADD PRIMARY KEY (`location_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bibliographic_records`
--
ALTER TABLE `bibliographic_records`
  ADD CONSTRAINT `fk_bib_publisher` FOREIGN KEY (`publisher_id`) REFERENCES `publishers` (`publisher_id`) ON DELETE SET NULL;

--
-- Constraints for table `book_copies`
--
ALTER TABLE `book_copies`
  ADD CONSTRAINT `fk_copy_bib` FOREIGN KEY (`bib_id`) REFERENCES `bibliographic_records` (`bib_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_copy_location` FOREIGN KEY (`location_id`) REFERENCES `shelf_locations` (`location_id`) ON DELETE SET NULL;

--
-- Constraints for table `borrow_transactions`
--
ALTER TABLE `borrow_transactions`
  ADD CONSTRAINT `fk_tx_copy` FOREIGN KEY (`copy_id`) REFERENCES `book_copies` (`copy_id`),
  ADD CONSTRAINT `fk_tx_issuer` FOREIGN KEY (`issued_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_tx_reader` FOREIGN KEY (`reader_id`) REFERENCES `readers` (`reader_id`),
  ADD CONSTRAINT `fk_tx_receiver` FOREIGN KEY (`returned_to`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `chat_messages`
--
ALTER TABLE `chat_messages`
  ADD CONSTRAINT `fk_chat_reader` FOREIGN KEY (`reader_id`) REFERENCES `readers` (`reader_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_chat_sender` FOREIGN KEY (`sender_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `holds`
--
ALTER TABLE `holds`
  ADD CONSTRAINT `fk_hold_bib` FOREIGN KEY (`bib_id`) REFERENCES `bibliographic_records` (`bib_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_hold_reader` FOREIGN KEY (`reader_id`) REFERENCES `readers` (`reader_id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `fk_notif_reader` FOREIGN KEY (`reader_id`) REFERENCES `readers` (`reader_id`) ON DELETE CASCADE;

--
-- Constraints for table `readers`
--
ALTER TABLE `readers`
  ADD CONSTRAINT `fk_reader_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `reader_preferences`
--
ALTER TABLE `reader_preferences`
  ADD CONSTRAINT `fk_pref_reader` FOREIGN KEY (`reader_id`) REFERENCES `readers` (`reader_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
