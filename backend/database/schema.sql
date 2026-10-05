SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS users (
    user_id VARCHAR(36) NOT NULL,
    username VARCHAR(100) NOT NULL,
    email VARCHAR(255) DEFAULT NULL,
    full_name VARCHAR(200) DEFAULT NULL,
    phone VARCHAR(20) DEFAULT NULL,
    avatar_url TEXT DEFAULT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'librarian', 'reader') NOT NULL DEFAULT 'reader',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id),
    UNIQUE KEY uq_users_username (username),
    KEY idx_users_email (email),
    KEY idx_users_role_active (role, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS publishers (
    publisher_id VARCHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    address TEXT DEFAULT NULL,
    contact_email VARCHAR(255) DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (publisher_id),
    KEY idx_publishers_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS categories (
    category_id VARCHAR(36) NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    ddc_code VARCHAR(20) DEFAULT NULL,
    description TEXT DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (category_id),
    UNIQUE KEY uq_categories_name (category_name),
    KEY idx_categories_ddc (ddc_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS shelf_locations (
    location_id VARCHAR(36) NOT NULL,
    floor SMALLINT NOT NULL,
    section VARCHAR(20) NOT NULL,
    shelf VARCHAR(10) NOT NULL,
    position VARCHAR(10) DEFAULT NULL,
    capacity INT NOT NULL DEFAULT 50,
    ddc_range VARCHAR(50) DEFAULT NULL,
    PRIMARY KEY (location_id),
    KEY idx_shelves_position (floor, section, shelf)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS readers (
    reader_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) DEFAULT NULL,
    reader_code VARCHAR(20) NOT NULL,
    full_name VARCHAR(200) NOT NULL,
    birth_date DATE DEFAULT NULL,
    phone VARCHAR(20) DEFAULT NULL,
    email VARCHAR(255) DEFAULT NULL,
    address TEXT DEFAULT NULL,
    reader_type ENUM('student', 'lecturer', 'staff', 'public') NOT NULL DEFAULT 'student',
    faculty VARCHAR(200) DEFAULT NULL,
    card_issued DATE DEFAULT NULL,
    card_expired DATE DEFAULT NULL,
    status ENUM('active', 'suspended', 'expired') NOT NULL DEFAULT 'active',
    max_books SMALLINT NOT NULL DEFAULT 5,
    avatar_url TEXT DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (reader_id),
    UNIQUE KEY uq_readers_code (reader_code),
    UNIQUE KEY uq_readers_user (user_id),
    KEY idx_readers_status_expired (status, card_expired),
    KEY idx_readers_name (full_name),
    CONSTRAINT fk_reader_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS bibliographic_records (
    bib_id VARCHAR(36) NOT NULL,
    isbn VARCHAR(20) DEFAULT NULL,
    title VARCHAR(500) NOT NULL,
    subtitle VARCHAR(500) DEFAULT NULL,
    authors JSON NOT NULL,
    publisher_id VARCHAR(36) DEFAULT NULL,
    publish_year SMALLINT DEFAULT NULL,
    edition VARCHAR(50) DEFAULT NULL,
    language VARCHAR(10) DEFAULT 'vi',
    description TEXT DEFAULT NULL,
    page_count INT DEFAULT NULL,
    call_number VARCHAR(50) DEFAULT NULL,
    ddc_class VARCHAR(20) DEFAULT NULL,
    subject_headings JSON DEFAULT NULL,
    keywords JSON DEFAULT NULL,
    cover_url TEXT DEFAULT NULL,
    metadata JSON DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (bib_id),
    KEY idx_books_isbn (isbn),
    KEY idx_books_title (title(191)),
    KEY idx_books_publisher (publisher_id),
    KEY idx_books_ddc_language_year (ddc_class, language, publish_year),
    CONSTRAINT fk_bib_publisher FOREIGN KEY (publisher_id) REFERENCES publishers(publisher_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS book_copies (
    copy_id VARCHAR(36) NOT NULL,
    bib_id VARCHAR(36) NOT NULL,
    barcode VARCHAR(50) NOT NULL,
    `condition` ENUM('new', 'good', 'fair', 'poor', 'damaged') NOT NULL DEFAULT 'good',
    location_id VARCHAR(36) DEFAULT NULL,
    status ENUM('available', 'borrowed', 'reserved', 'lost', 'processing') NOT NULL DEFAULT 'available',
    acquired_date DATE DEFAULT NULL,
    acquired_price DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY (copy_id),
    UNIQUE KEY uq_book_copies_barcode (barcode),
    KEY idx_copies_bib_status (bib_id, status),
    KEY idx_copies_location (location_id),
    CONSTRAINT fk_copy_bib FOREIGN KEY (bib_id) REFERENCES bibliographic_records(bib_id) ON DELETE CASCADE,
    CONSTRAINT fk_copy_location FOREIGN KEY (location_id) REFERENCES shelf_locations(location_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS reader_preferences (
    reader_id VARCHAR(36) NOT NULL,
    preferred_subjects JSON DEFAULT NULL,
    preferred_authors JSON DEFAULT NULL,
    preferred_langs JSON DEFAULT NULL,
    reading_pace ENUM('slow', 'medium', 'fast') NOT NULL DEFAULT 'medium',
    notification_pref JSON DEFAULT NULL,
    PRIMARY KEY (reader_id),
    CONSTRAINT fk_pref_reader FOREIGN KEY (reader_id) REFERENCES readers(reader_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS borrow_transactions (
    tx_id VARCHAR(36) NOT NULL,
    reader_id VARCHAR(36) NOT NULL,
    copy_id VARCHAR(36) NOT NULL,
    borrow_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE DEFAULT NULL,
    renewed_count SMALLINT NOT NULL DEFAULT 0,
    status ENUM('borrowed', 'returned', 'overdue', 'lost') NOT NULL DEFAULT 'borrowed',
    fine_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    fine_paid TINYINT(1) NOT NULL DEFAULT 0,
    report_reason VARCHAR(30) DEFAULT NULL,
    report_note TEXT DEFAULT NULL,
    report_evidence_url TEXT DEFAULT NULL,
    reported_at DATETIME DEFAULT NULL,
    issued_by VARCHAR(36) DEFAULT NULL,
    returned_to VARCHAR(36) DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (tx_id),
    KEY idx_transactions_reader_status (reader_id, status),
    KEY idx_transactions_copy_status (copy_id, status),
    KEY idx_transactions_due_status (due_date, status),
    KEY idx_transactions_issuer (issued_by),
    KEY idx_transactions_receiver (returned_to),
    CONSTRAINT fk_tx_reader FOREIGN KEY (reader_id) REFERENCES readers(reader_id),
    CONSTRAINT fk_tx_copy FOREIGN KEY (copy_id) REFERENCES book_copies(copy_id),
    CONSTRAINT fk_tx_issuer FOREIGN KEY (issued_by) REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_tx_receiver FOREIGN KEY (returned_to) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS renewal_requests (
    request_id VARCHAR(36) NOT NULL,
    tx_id VARCHAR(36) NOT NULL,
    reader_id VARCHAR(36) NOT NULL,
    requested_days TINYINT UNSIGNED NOT NULL DEFAULT 7,
    approved_days TINYINT UNSIGNED DEFAULT NULL,
    status ENUM('pending', 'approved', 'rejected', 'cancelled') NOT NULL DEFAULT 'pending',
    processed_by VARCHAR(36) DEFAULT NULL,
    processed_at DATETIME DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (request_id),
    KEY idx_renewal_tx_status (tx_id, status),
    KEY idx_renewal_reader (reader_id),
    KEY idx_renewal_processor (processed_by),
    CONSTRAINT fk_renewal_transaction FOREIGN KEY (tx_id) REFERENCES borrow_transactions(tx_id) ON DELETE CASCADE,
    CONSTRAINT fk_renewal_reader FOREIGN KEY (reader_id) REFERENCES readers(reader_id) ON DELETE CASCADE,
    CONSTRAINT fk_renewal_processor FOREIGN KEY (processed_by) REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_renewal_requested_days CHECK (requested_days BETWEEN 1 AND 7),
    CONSTRAINT chk_renewal_approved_days CHECK (approved_days IS NULL OR approved_days BETWEEN 1 AND 7)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS holds (
    hold_id VARCHAR(36) NOT NULL,
    reader_id VARCHAR(36) NOT NULL,
    bib_id VARCHAR(36) NOT NULL,
    requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notified_at DATETIME DEFAULT NULL,
    expires_at DATETIME DEFAULT NULL,
    status ENUM('waiting', 'notified', 'fulfilled', 'cancelled', 'expired') NOT NULL DEFAULT 'waiting',
    queue_position INT DEFAULT 1,
    PRIMARY KEY (hold_id),
    KEY idx_holds_reader_status (reader_id, status),
    KEY idx_holds_bib_queue (bib_id, status, queue_position),
    KEY idx_holds_expiration (status, expires_at),
    CONSTRAINT fk_hold_reader FOREIGN KEY (reader_id) REFERENCES readers(reader_id) ON DELETE CASCADE,
    CONSTRAINT fk_hold_bib FOREIGN KEY (bib_id) REFERENCES bibliographic_records(bib_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notifications (
    notification_id VARCHAR(36) NOT NULL,
    reader_id VARCHAR(36) NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    type ENUM('hold_available', 'due_soon', 'overdue', 'card_expired', 'system') NOT NULL DEFAULT 'system',
    reference_id VARCHAR(36) DEFAULT NULL,
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (notification_id),
    KEY idx_notifications_reader_read_created (reader_id, is_read, created_at),
    KEY idx_notifications_type_reference (type, reference_id),
    CONSTRAINT fk_notif_reader FOREIGN KEY (reader_id) REFERENCES readers(reader_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS chat_messages (
    message_id VARCHAR(36) NOT NULL,
    reader_id VARCHAR(36) NOT NULL,
    sender_id VARCHAR(36) NOT NULL,
    sender_role ENUM('reader', 'librarian') NOT NULL,
    message_text TEXT NOT NULL,
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (message_id),
    KEY idx_chat_reader_created (reader_id, created_at),
    KEY idx_chat_reader_unread (reader_id, sender_role, is_read),
    KEY idx_chat_sender (sender_id),
    CONSTRAINT fk_chat_reader FOREIGN KEY (reader_id) REFERENCES readers(reader_id) ON DELETE CASCADE,
    CONSTRAINT fk_chat_sender FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS password_resets (
    email VARCHAR(255) NOT NULL,
    otp VARCHAR(10) NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (email),
    KEY idx_password_resets_expiration (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS token_blacklist (
    id INT NOT NULL AUTO_INCREMENT,
    token VARCHAR(500) NOT NULL,
    user_id VARCHAR(36) DEFAULT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_token_blacklist_token (token(255)),
    KEY idx_token_blacklist_expiration (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ai_conversations (
    conversation_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    title VARCHAR(255) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (conversation_id),
    KEY idx_ai_conversations_user_updated (user_id, updated_at),
    CONSTRAINT fk_ai_conversations_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ai_messages (
    message_id VARCHAR(36) NOT NULL,
    conversation_id VARCHAR(36) NOT NULL,
    role ENUM('user', 'model') NOT NULL,
    content MEDIUMTEXT NOT NULL,
    tool_name VARCHAR(500) DEFAULT NULL,
    sources JSON DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (message_id),
    KEY idx_ai_messages_conversation_created (conversation_id, created_at),
    CONSTRAINT fk_ai_messages_conversation FOREIGN KEY (conversation_id) REFERENCES ai_conversations(conversation_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ai_usage_logs (
    log_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) DEFAULT NULL,
    conversation_id VARCHAR(36) DEFAULT NULL,
    model VARCHAR(100) NOT NULL,
    tools_called VARCHAR(500) DEFAULT NULL,
    response_time_ms INT UNSIGNED NOT NULL DEFAULT 0,
    status ENUM('success', 'failed', 'timeout') NOT NULL,
    error_message TEXT DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (log_id),
    KEY idx_ai_usage_user_created (user_id, created_at),
    KEY idx_ai_usage_conversation (conversation_id),
    CONSTRAINT fk_ai_usage_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_ai_usage_conversation FOREIGN KEY (conversation_id) REFERENCES ai_conversations(conversation_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
