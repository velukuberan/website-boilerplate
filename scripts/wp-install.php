<?php
/**
 * Simple WordPress Auto-Installer
 * Just works - no config files, no over-engineering
 */

echo "🐳 Installing WordPress...\n";

// Simple configuration - edit these values directly in the script
$wp_title = $_ENV['WP_TITLE'] ?? 'My WordPress Site';
$wp_admin_user = $_ENV['WP_ADMIN_USER'] ?? 'admin';
$wp_admin_password = $_ENV['WP_ADMIN_PASSWORD'] ?? 'admin123';
$wp_admin_email = $_ENV['WP_ADMIN_EMAIL'] ?? 'admin@example.com';
$wp_url = $_ENV['WP_HOME'] ?? 'http://localhost:8080';

// Wait for database
echo "⏳ Waiting for database...\n";
$attempts = 0;
while ($attempts < 30) {
    $result = shell_exec('wp db check 2>&1');
    if (strpos($result, 'Success') !== false) {
        break;
    }
    sleep(2);
    $attempts++;
}

if ($attempts >= 30) {
    echo "❌ Database connection failed\n";
    exit(1);
}

// Check if WordPress is already installed
$installed = shell_exec('wp core is-installed 2>&1; echo $?');
if (trim($installed) === '0') {
    echo "✅ WordPress is already installed\n";
    exit(0);
}

// Install WordPress
echo "📦 Installing WordPress core...\n";
$install_cmd = sprintf(
    'wp core install --url="%s" --title="%s" --admin_user="%s" --admin_password="%s" --admin_email="%s" --skip-email',
    $wp_url, $wp_title, $wp_admin_user, $wp_admin_password, $wp_admin_email
);

$result = shell_exec($install_cmd . ' 2>&1');
if (strpos($result, 'Success') === false) {
    echo "❌ WordPress installation failed: $result\n";
    exit(1);
}

// Basic setup
echo "⚙️ Setting up WordPress...\n";
shell_exec('wp core update 2>/dev/null');
shell_exec('wp rewrite structure "/%postname%/" 2>/dev/null');
shell_exec('wp rewrite flush 2>/dev/null');

// Install basic plugins
echo "🔌 Installing plugins...\n";
$plugins = ['contact-form-7', 'yoast-seo'];
foreach ($plugins as $plugin) {
    shell_exec("wp plugin install $plugin --activate 2>/dev/null");
}

// Done
echo "\n✅ WordPress installed successfully!\n";
echo "🌐 Site: $wp_url\n";
echo "👤 Admin: $wp_admin_user / $wp_admin_password\n";
echo "📧 Email: $wp_admin_email\n";
echo "\nAccess admin: $wp_url/wp/wp-admin\n";
