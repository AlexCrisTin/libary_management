SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'readers' AND COLUMN_NAME = 'address') = 0,
  'ALTER TABLE `readers` ADD COLUMN `address` text DEFAULT NULL AFTER `email`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
