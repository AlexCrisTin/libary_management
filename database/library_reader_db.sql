-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 20, 2026 at 03:26 PM
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
-- Database: `library_reader_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `readers`
--

CREATE TABLE `readers` (
  `reader_id` varchar(36) NOT NULL,
  `user_id` varchar(36) DEFAULT NULL COMMENT 'Reference logic to library_auth_db.users.user_id',
  `reader_code` varchar(20) NOT NULL COMMENT 'VD: LIB-2024-00001',
  `full_name` varchar(200) NOT NULL,
  `birth_date` date DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `reader_type` enum('student','lecturer','staff','public') DEFAULT 'student',
  `faculty` varchar(200) DEFAULT NULL COMMENT 'Khoa neu la SV/GV',
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
  `preferred_subjects` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`preferred_subjects`)),
  `preferred_authors` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`preferred_authors`)),
  `preferred_langs` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`preferred_langs`)),
  `reading_pace` enum('slow','medium','fast') DEFAULT 'medium',
  `notification_pref` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`notification_pref`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `readers`
--
ALTER TABLE `readers`
  ADD PRIMARY KEY (`reader_id`),
  ADD UNIQUE KEY `reader_code` (`reader_code`),
  ADD KEY `idx_reader_user_id` (`user_id`);

--
-- Indexes for table `reader_preferences`
--
ALTER TABLE `reader_preferences`
  ADD PRIMARY KEY (`reader_id`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `reader_preferences`
--
ALTER TABLE `reader_preferences`
  ADD CONSTRAINT `fk_pref_reader` FOREIGN KEY (`reader_id`) REFERENCES `readers` (`reader_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
