-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 06, 2026 at 09:57 AM
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
  `ddc_range` varchar(50) DEFAULT NULL COMMENT '000-099 Tin học...'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
-- Indexes for table `holds`
--
ALTER TABLE `holds`
  ADD PRIMARY KEY (`hold_id`),
  ADD KEY `fk_hold_reader` (`reader_id`),
  ADD KEY `fk_hold_bib` (`bib_id`);

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
-- Constraints for table `holds`
--
ALTER TABLE `holds`
  ADD CONSTRAINT `fk_hold_bib` FOREIGN KEY (`bib_id`) REFERENCES `bibliographic_records` (`bib_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_hold_reader` FOREIGN KEY (`reader_id`) REFERENCES `readers` (`reader_id`) ON DELETE CASCADE;

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
