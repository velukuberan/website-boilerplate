<?php
/**
 * Check versions of all components in the stack
 * WordPress + Bedrock + MariaDB + PHP + Docker environment
 */

class VersionChecker
{
    public function run()
    {
        echo str_repeat("=", 60) . "\n";
        echo "🔍 WordPress Bedrock Stack Version Check\n";
        echo str_repeat("=", 60) . "\n";

        $this->checkPHP();
        $this->checkWordPress();
        $this->checkBedrock();
        $this->checkMariaDB();
        $this->checkRedis();
        $this->checkComposer();
        
        echo str_repeat("=", 60) . "\n";
        echo "✅ Version check complete!\n";
    }

    private function checkPHP()
    {
        echo "🐘 PHP Version: " . PHP_VERSION . "\n";
        echo "   • Extensions: " . implode(', ', $this->getImportantExtensions()) . "\n";
        echo "   • Memory Limit: " . ini_get('memory_limit') . "\n";
        echo "   • Max Execution Time: " . ini_get('max_execution_time') . "s\n";
        echo "\n";
    }

    private function checkWordPress()
    {
        $composerLock = $this->getComposerLock();
        $wpVersion = $this->findPackageVersion($composerLock, 'johnpbloch/wordpress');
        
        echo "🌐 WordPress: " . ($wpVersion ?: 'Not found') . "\n";
        
        // Check if WordPress is actually installed
        if (file_exists('web/wp/wp-includes/version.php')) {
            include_once 'web/wp/wp-includes/version.php';
            global $wp_version;
            echo "   • Installed Version: " . ($wp_version ?? 'Unknown') . "\n";
        }
        echo "\n";
    }

    private function checkBedrock()
    {
        $composerLock = $this->getComposerLock();
        $bedrockVersion = $this->findPackageVersion($composerLock, 'roots/bedrock');
        
        echo "🏗️  Bedrock: " . ($bedrockVersion ?: 'Not found') . "\n";
        echo "\n";
    }

    private function checkMariaDB()
    {
        echo "🗄️  MariaDB Connection Test:\n";
        
        if (!$this->loadEnv()) {
            echo "   ❌ Could not load .env file\n\n";
            return;
        }

        $host = $_ENV['DB_HOST'] ?? 'mariadb';
        $dbname = $_ENV['DB_NAME'] ?? 'wordpress';
        $username = $_ENV['DB_USER'] ?? 'wordpress';
        $password = $_ENV['DB_PASSWORD'] ?? 'wordpress';

        try {
            $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            
            // Get MariaDB version
            $stmt = $pdo->query('SELECT VERSION() as version');
            $version = $stmt->fetch(PDO::FETCH_ASSOC);
            
            echo "   ✅ Connected successfully\n";
            echo "   • Version: " . $version['version'] . "\n";
            
            // Check charset
            $stmt = $pdo->query('SELECT @@character_set_server as charset, @@collation_server as collation');
            $charset = $stmt->fetch(PDO::FETCH_ASSOC);
            echo "   • Charset: " . $charset['charset'] . " / " . $charset['collation'] . "\n";
            
        } catch (PDOException $e) {
            echo "   ❌ Connection failed: " . $e->getMessage() . "\n";
        }
        echo "\n";
    }

    private function checkRedis()
    {
        echo "🔄 Redis Connection Test:\n";
        
        if (!extension_loaded('redis')) {
            echo "   ❌ Redis extension not loaded\n\n";
            return;
        }

        try {
            $redis = new Redis();
            $redis->connect('redis', 6379);
            $info = $redis->info();
            
            echo "   ✅ Connected successfully\n";
            echo "   • Version: " . $info['redis_version'] . "\n";
            echo "   • Memory: " . $info['used_memory_human'] . "\n";
            
        } catch (Exception $e) {
            echo "   ❌ Connection failed: " . $e->getMessage() . "\n";
        }
        echo "\n";
    }

    private function checkComposer()
    {
        $composerJson = $this->getComposerJson();
        if ($composerJson) {
            echo "📦 Compser Dependencies:\n";
            echo "   • PHP Requirement: " . ($composerJson['require']['php'] ?? 'Not specified') . "\n";
            echo "   • Total Packages: " . count($composerJson['require'] ?? []) . "\n";
        }
        echo "\n";
    }

    private function getImportantExtensions()
    {
        $important = ['mysqli', 'pdo_mysql', 'gd', 'zip', 'intl', 'mbstring', 'opcache', 'redis'];
        $loaded = [];
        
        foreach ($important as $ext) {
            if (extension_loaded($ext)) {
                $loaded[] = $ext;
            }
        }
        
        return $loaded;
    }

    private function getComposerLock()
    {
        if (!file_exists('composer.lock')) {
            return null;
        }
        
        return json_decode(file_get_contents('composer.lock'), true);
    }

    private function getComposerJson()
    {
        if (!file_exists('composer.json')) {
            return null;
        }
        
        return json_decode(file_get_contents('composer.json'), true);
    }

    private function findPackageVersion($composerLock, $packageName)
    {
        if (!$composerLock || !isset($composerLock['packages'])) {
            return null;
        }

        foreach ($composerLock['packages'] as $package) {
            if ($package['name'] === $packageName) {
                return $package['version'];
            }
        }

        return null;
    }

    private function loadEnv()
    {
        if (!file_exists('.env')) {
            return false;
        }

        $lines = file('.env', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($lines as $line) {
            if (strpos($line, '=') !== false && !str_starts_with($line, '#')) {
                list($key, $value) = explode('=', $line, 2);
                $_ENV[trim($key)] = trim($value, '"\'');
            }
        }

        return true;
    }
}

// Only run if called directly
if (basename(__FILE__) == basename($_SERVER['SCRIPT_NAME'])) {
    $checker = new VersionChecker();
    $checker->run();
}

