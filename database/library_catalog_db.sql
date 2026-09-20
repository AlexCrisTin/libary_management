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
-- Database: `library_catalog_db`
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
  `authors` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`authors`)),
  `publisher_id` varchar(36) DEFAULT NULL,
  `publish_year` smallint(6) DEFAULT NULL,
  `edition` varchar(50) DEFAULT NULL,
  `language` varchar(10) DEFAULT 'vi',
  `description` text DEFAULT NULL,
  `page_count` int(11) DEFAULT NULL,
  `call_number` varchar(50) DEFAULT NULL,
  `ddc_class` varchar(20) DEFAULT NULL,
  `subject_headings` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`subject_headings`)),
  `keywords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`keywords`)),
  `cover_url` text DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `book_copies`
--

CREATE TABLE `book_copies` (
  `copy_id` varchar(36) NOT NULL,
  `bib_id` varchar(36) NOT NULL,
  `barcode` varchar(50) NOT NULL,
  `condition` enum('new','good','fair','poor','damaged') DEFAULT 'good',
  `location_id` varchar(36) DEFAULT NULL,
  `status` enum('available','borrowed','reserved','lost','processing') DEFAULT 'available',
  `acquired_date` date DEFAULT NULL,
  `acquired_price` decimal(12,2) DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `category_id` varchar(36) NOT NULL,
  `category_name` varchar(100) NOT NULL,
  `ddc_code` varchar(20) DEFAULT NULL,
  `description` text DEFAULT NULL,
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
-- Table structure for table `shelf_locations`
--

CREATE TABLE `shelf_locations` (
  `location_id` varchar(36) NOT NULL,
  `floor` smallint(6) NOT NULL,
  `section` varchar(20) NOT NULL,
  `shelf` varchar(10) NOT NULL,
  `position` varchar(10) DEFAULT NULL,
  `capacity` int(11) DEFAULT 50,
  `ddc_range` varchar(50) DEFAULT NULL
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
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`category_id`),
  ADD UNIQUE KEY `category_name` (`category_name`);

--
-- Indexes for table `publishers`
--
ALTER TABLE `publishers`
  ADD PRIMARY KEY (`publisher_id`);

--
-- Indexes for table `shelf_locations`
--
ALTER TABLE `shelf_locations`
  ADD PRIMARY KEY (`location_id`);

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
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
