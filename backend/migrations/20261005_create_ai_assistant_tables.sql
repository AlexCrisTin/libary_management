CREATE TABLE IF NOT EXISTS ai_conversations (
    conversation_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    title VARCHAR(255) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (conversation_id),
    KEY idx_ai_conversations_user_updated (user_id, updated_at),
    CONSTRAINT fk_ai_conversations_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE
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
    CONSTRAINT fk_ai_messages_conversation
        FOREIGN KEY (conversation_id) REFERENCES ai_conversations(conversation_id)
        ON DELETE CASCADE
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
    CONSTRAINT fk_ai_usage_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_ai_usage_conversation
        FOREIGN KEY (conversation_id) REFERENCES ai_conversations(conversation_id)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
