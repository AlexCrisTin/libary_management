CREATE TABLE IF NOT EXISTS `renewal_requests` (
  `request_id` varchar(36) NOT NULL,
  `tx_id` varchar(36) NOT NULL,
  `reader_id` varchar(36) NOT NULL,
  `requested_days` tinyint unsigned NOT NULL DEFAULT 7,
  `approved_days` tinyint unsigned DEFAULT NULL,
  `status` enum('pending','approved','rejected','cancelled') NOT NULL DEFAULT 'pending',
  `processed_by` varchar(36) DEFAULT NULL,
  `processed_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`request_id`),
  KEY `idx_renewal_tx_status` (`tx_id`, `status`),
  KEY `idx_renewal_reader` (`reader_id`),
  KEY `fk_renewal_processor` (`processed_by`),
  CONSTRAINT `fk_renewal_transaction` FOREIGN KEY (`tx_id`) REFERENCES `borrow_transactions` (`tx_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_renewal_reader` FOREIGN KEY (`reader_id`) REFERENCES `readers` (`reader_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_renewal_processor` FOREIGN KEY (`processed_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
