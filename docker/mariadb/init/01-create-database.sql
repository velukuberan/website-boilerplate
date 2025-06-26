-- WordPress MariaDB Initialization Script
-- This script runs when the MariaDB container starts for the first time

-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS `wordpress` 
DEFAULT CHARACTER SET utf8mb4 
DEFAULT COLLATE utf8mb4_unicode_ci;

-- Create user if it doesn't exist (MariaDB 10.1+ syntax)
CREATE OR REPLACE USER 'wordpress'@'%' IDENTIFIED BY 'wordpress';

-- Grant privileges
GRANT ALL PRIVILEGES ON `wordpress`.* TO 'wordpress'@'%';

-- Additional useful privileges for WordPress
GRANT FILE ON *.* TO 'wordpress'@'%';
GRANT PROCESS ON *.* TO 'wordpress'@'%';
GRANT RELOAD ON *.* TO 'wordpress'@'%';

-- Flush privileges
FLUSH PRIVILEGES;

-- MariaDB-specific optimizations for WordPress
SET GLOBAL innodb_buffer_pool_size = 512 * 1024 * 1024;
SET GLOBAL innodb_log_file_size = 128 * 1024 * 1024;
SET GLOBAL max_allowed_packet = 64 * 1024 * 1024;
SET GLOBAL query_cache_size = 64 * 1024 * 1024;
SET GLOBAL query_cache_type = 1;

-- Enable performance schema for monitoring
SET GLOBAL performance_schema = ON;

-- Use the WordPress database
USE wordpress;

-- Create a test table to verify connection and charset
CREATE TABLE IF NOT EXISTS wp_setup_test (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    emoji_test VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '🚀✨📱',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert test data with emojis to verify utf8mb4 support
INSERT INTO wp_setup_test (message, emoji_test) VALUES 
('MariaDB initialized successfully for WordPress! 🎉', '🚀⚡🐳'),
('UTF8MB4 charset working correctly', '💻📝✅'),
('Ready for WordPress installation', '🏗️🔧⭐');

-- Display setup completion message
SELECT 
    'MariaDB Setup Complete!' as status,
    VERSION() as mariadb_version,
    @@character_set_server as charset,
    @@collation_server as collation,
    @@innodb_buffer_pool_size / 1024 / 1024 as buffer_pool_mb;

-- Show test data to verify emoji support
SELECT * FROM wp_setup_test;
