SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'borrow_transactions' AND COLUMN_NAME = 'report_reason') = 0,
  'ALTER TABLE `borrow_transactions` ADD COLUMN `report_reason` varchar(30) DEFAULT NULL AFTER `fine_paid`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'borrow_transactions' AND COLUMN_NAME = 'report_note') = 0,
  'ALTER TABLE `borrow_transactions` ADD COLUMN `report_note` text DEFAULT NULL AFTER `report_reason`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'borrow_transactions' AND COLUMN_NAME = 'report_evidence_url') = 0,
  'ALTER TABLE `borrow_transactions` ADD COLUMN `report_evidence_url` text DEFAULT NULL AFTER `report_note`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'borrow_transactions' AND COLUMN_NAME = 'reported_at') = 0,
  'ALTER TABLE `borrow_transactions` ADD COLUMN `reported_at` datetime DEFAULT NULL AFTER `report_evidence_url`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
