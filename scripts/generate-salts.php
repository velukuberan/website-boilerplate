<?php
/**
 * Generate WordPress salts and update .env file
 * Part of WordPress Bedrock + MariaDB + Docker boilerplate
 */

class SaltGenerator
{
    private $envFile = '.env';
    private $saltKeys = [
        'AUTH_KEY',
        'SECURE_AUTH_KEY',
        'LOGGED_IN_KEY',
        'NONCE_KEY',
        'AUTH_SALT',
        'SECURE_AUTH_SALT',
        'LOGGED_IN_SALT',
        'NONCE_SALT'
    ];

    public function run()
    {
        echo "🔐 Generating WordPress security salts...\n";

        if (!file_exists($this->envFile)) {
            echo "❌ .env file not found. Please run 'composer install' first.\n";
            return;
        }

        $envContent = file_get_contents($this->envFile);
        $needsUpdate = false;

        foreach ($this->saltKeys as $key) {
            if (preg_match("/^{$key}=''$/m", $envContent) || preg_match("/^{$key}=$/m", $envContent)) {
                $salt = $this->generateSalt();
                $envContent = preg_replace("/^{$key}=.*$/m", "{$key}='{$salt}'", $envContent);
                $needsUpdate = true;
                echo "✅ Generated {$key}\n";
            }
        }

        if ($needsUpdate) {
            file_put_contents($this->envFile, $envContent);
            echo "✅ WordPress salts updated in .env file\n";
        } else {
            echo "ℹ️  WordPress salts already configured\n";
        }
    }

    private function generateSalt($length = 64)
    {
        $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?';
        $salt = '';
        $max = strlen($chars) - 1;

        for ($i = 0; $i < $length; $i++) {
            $salt .= $chars[random_int(0, $max)];
        }

        return $salt;
    }
}

// Only run if called directly
if (basename(__FILE__) == basename($_SERVER['SCRIPT_NAME'])) {
    $generator = new SaltGenerator();
    $generator->run();
}
