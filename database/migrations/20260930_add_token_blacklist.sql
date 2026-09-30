CREATE TABLE IF NOT EXISTS `token_blacklist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `token` varchar(500) NOT NULL,
  `user_id` varchar(36) DEFAULT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_token` (`token`(255)),
  KEY `idx_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
