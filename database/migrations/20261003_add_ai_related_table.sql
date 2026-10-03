-- ====================================================================
-- MODULE AI LIBRARIAN ASSISTANT (TRO LY AO THU THU)
-- ====================================================================

-- 1. Bang luu cac phien tro chuyen cua Thu thu / Admin
CREATE TABLE IF NOT EXISTS `ai_conversations` (
  `conversation_id` VARCHAR(36) NOT NULL,
  `user_id` VARCHAR(36) NOT NULL COMMENT 'ID thu thu hoac admin tao phien chat',
  `title` VARCHAR(255) DEFAULT 'Cuoc tro chuyen moi' COMMENT 'Tieu de tom tat cuoc tro chuyen',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`conversation_id`),
  KEY `fk_ai_conv_user` (`user_id`),
  CONSTRAINT `fk_ai_conv_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Bang luu chi tiet cac tin nhan trong tung phien hoi thoai
CREATE TABLE IF NOT EXISTS `ai_messages` (
  `message_id` VARCHAR(36) NOT NULL,
  `conversation_id` VARCHAR(36) NOT NULL COMMENT 'Thuoc ve phien hoi thoai nao',
  `role` ENUM('user', 'model', 'system', 'tool') NOT NULL COMMENT 'Vai tro nguoi gui: user (thu thu), model (Gemini), system, tool',
  `content` TEXT NOT NULL COMMENT 'Noi dung tin nhan hoac ket qua phan hoi',
  `tool_name` VARCHAR(100) DEFAULT NULL COMMENT 'Ten cong cu duoc goi (neu co)',
  `sources` TEXT DEFAULT NULL COMMENT 'Nguon du lieu tham chieu dang JSON (neu co)',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`message_id`),
  KEY `fk_ai_msg_conv` (`conversation_id`),
  CONSTRAINT `fk_ai_msg_conv` FOREIGN KEY (`conversation_id`) REFERENCES `ai_conversations` (`conversation_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Bang ghi log luot su dung va giam sat tieu thu Token (Muc 11 trong tai lieu)
CREATE TABLE IF NOT EXISTS `ai_usage_logs` (
  `log_id` VARCHAR(36) NOT NULL,
  `user_id` VARCHAR(36) NOT NULL,
  `conversation_id` VARCHAR(36) DEFAULT NULL,
  `model` VARCHAR(100) NOT NULL COMMENT 'Ten model Gemini su dung (vi du: gemini-3.7-flash, gemini-1.5-flash)',
  `tools_called` VARCHAR(255) DEFAULT NULL COMMENT 'Cac cong cu da duoc thuc thi trong luot hoi nay',
  `prompt_tokens` INT DEFAULT 0,
  `candidates_tokens` INT DEFAULT 0,
  `total_tokens` INT DEFAULT 0,
  `response_time_ms` INT DEFAULT 0 COMMENT 'Thoi gian phan hoi tinh bang mili-giay',
  `status` ENUM('success', 'failed', 'timeout', 'rate_limited') DEFAULT 'success',
  `error_message` TEXT DEFAULT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`log_id`),
  KEY `fk_ai_log_user` (`user_id`),
  CONSTRAINT `fk_ai_log_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;