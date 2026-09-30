SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'email') = 0,
  'ALTER TABLE `users` ADD COLUMN `email` varchar(255) DEFAULT NULL AFTER `username`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'full_name') = 0,
  'ALTER TABLE `users` ADD COLUMN `full_name` varchar(200) DEFAULT NULL AFTER `email`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'phone') = 0,
  'ALTER TABLE `users` ADD COLUMN `phone` varchar(20) DEFAULT NULL AFTER `full_name`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'avatar_url') = 0,
  'ALTER TABLE `users` ADD COLUMN `avatar_url` text DEFAULT NULL AFTER `phone`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE `users` AS u
JOIN `readers` AS r ON r.user_id = u.user_id
SET
  u.email = COALESCE(u.email, r.email),
  u.full_name = COALESCE(u.full_name, r.full_name),
  u.phone = COALESCE(u.phone, r.phone),
  u.avatar_url = COALESCE(u.avatar_url, r.avatar_url)
WHERE u.role = 'reader';

CREATE TABLE IF NOT EXISTS `password_resets` (
  `email` varchar(255) NOT NULL,
  `otp` varchar(10) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
