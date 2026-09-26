CREATE TABLE IF NOT EXISTS `chat_messages` (
  `message_id` varchar(36) NOT NULL,
  `reader_id` varchar(36) NOT NULL COMMENT 'Kênh chat thuộc về độc giả nào',
  `sender_id` varchar(36) NOT NULL COMMENT 'user_id của người gửi',
  `sender_role` enum('reader','librarian') NOT NULL,
  `message_text` text NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`message_id`),
  KEY `fk_chat_reader` (`reader_id`),
  KEY `fk_chat_sender` (`sender_id`),
  CONSTRAINT `fk_chat_reader` FOREIGN KEY (`reader_id`) REFERENCES `readers` (`reader_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_chat_sender` FOREIGN KEY (`sender_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `notifications` (
  `notification_id` varchar(36) NOT NULL,
  `reader_id` varchar(36) NOT NULL COMMENT 'Độc giả nhận thông báo',
  `title` varchar(255) NOT NULL,
  `content` text NOT NULL,
  `type` enum('hold_available','due_soon','overdue','card_expired','system') DEFAULT 'system',
  `reference_id` varchar(36) DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`notification_id`),
  KEY `fk_notif_reader` (`reader_id`),
  CONSTRAINT `fk_notif_reader` FOREIGN KEY (`reader_id`) REFERENCES `readers` (`reader_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
