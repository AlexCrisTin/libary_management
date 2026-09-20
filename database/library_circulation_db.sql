-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 20, 2026 at 03:24 PM
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
-- Database: `library_circulation_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `borrow_transactions`
--

CREATE TABLE `borrow_transactions` (
  `tx_id` varchar(36) NOT NULL,
  `reader_id` varchar(36) NOT NULL COMMENT 'Reference logic to library_reader_db.readers.reader_id',
  `copy_id` varchar(36) NOT NULL COMMENT 'Reference logic to library_catalog_db.book_copies.copy_id',
  `reader_code` varchar(20) DEFAULT NULL COMMENT 'Denormalized: Ma the doc gia',
  `reader_name` varchar(200) DEFAULT NULL COMMENT 'Denormalized: Ten doc gia',
  `book_title` varchar(500) DEFAULT NULL COMMENT 'Denormalized: Tua de sach',
  `barcode` varchar(50) DEFAULT NULL COMMENT 'Denormalized: Ma vach ban sach',
  `borrow_date` date NOT NULL,
  `due_date` date NOT NULL,
  `return_date` date DEFAULT NULL,
  `renewed_count` smallint(6) DEFAULT 0,
  `status` enum('borrowed','returned','overdue','lost') DEFAULT 'borrowed',
  `fine_amount` decimal(10,2) DEFAULT 0.00,
  `fine_paid` tinyint(1) DEFAULT 0,
  `issued_by` varchar(36) DEFAULT NULL COMMENT 'Reference logic to library_auth_db.users.user_id',
  `returned_to` varchar(36) DEFAULT NULL COMMENT 'Reference logic to library_auth_db.users.user_id',
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `holds`
--

CREATE TABLE `holds` (
  `hold_id` varchar(36) NOT NULL,
  `reader_id` varchar(36) NOT NULL COMMENT 'Reference logic to library_reader_db.readers.reader_id',
  `bib_id` varchar(36) NOT NULL COMMENT 'Reference logic to library_catalog_db.bibliographic_records.bib_id',
  `reader_name` varchar(200) DEFAULT NULL COMMENT 'Denormalized: Ten doc gia dat truoc',
  `book_title` varchar(500) DEFAULT NULL COMMENT 'Denormalized: Tua de sach dat truoc',
  `requested_at` datetime DEFAULT current_timestamp(),
  `notified_at` datetime DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  `status` enum('waiting','notified','fulfilled','cancelled','expired') DEFAULT 'waiting',
  `queue_position` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `borrow_transactions`
--
ALTER TABLE `borrow_transactions`
  ADD PRIMARY KEY (`tx_id`),
  ADD KEY `idx_tx_reader` (`reader_id`),
  ADD KEY `idx_tx_copy` (`copy_id`),
  ADD KEY `idx_tx_barcode` (`barcode`),
  ADD KEY `idx_tx_status` (`status`);

--
-- Indexes for table `holds`
--
ALTER TABLE `holds`
  ADD PRIMARY KEY (`hold_id`),
  ADD KEY `idx_hold_reader` (`reader_id`),
  ADD KEY `idx_hold_bib` (`bib_id`),
  ADD KEY `idx_hold_status` (`status`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
