<?php
/**
 * Docker setup script - runs after composer install
 * Configures WordPress + Bedrock + MariaDB + Docker environment
 */

class DockerSetup
{
    public function run()
    {
        echo "🐳 Setting up Docker environment with MariaDB...\n";

        $this->createDirectories();
        $this->setPermissions();
        $this->createInitFiles();
        $this->displayInstructions();
    }

    private function createDirectories()
    {
        $directories = [
            'web/app/uploads',
            'web/app/themes',
            'web/app/plugins',
            'web/app/mu-plugins',
            'logs',
            'docker/mariadb/init'
        ];

        foreach ($directories as $dir) {
            if (!is_dir($dir)) {
                mkdir($dir, 0755, true);
                echo "📁 Created directory: {$dir}\n";
            }
        }
    }

    private function setPermissions()
    {
        if (PHP_OS_FAMILY !== 'Windows') {
            $paths = [
                'web/app/uploads' => 0755,
                'logs' => 0755,
                'scripts' => 0755
            ];

            foreach ($paths as $path => $permission) {
                if (is_dir($path)) {
                    chmod($path, $permission);
                    echo "🔐 Set permissions for {$path}\n";
                }
            }

            // Make scripts executable
            $scripts = glob('scripts/*.php');
            foreach ($scripts as $script) {
                chmod($script, 0755);
            }
        }
    }

    private function createInitFiles()
    {
        // Create .htaccess for web directory
        $htaccess = "web/.htaccess";
        if (!file_exists($htaccess)) {
            $content = "# WordPress SEO by Yoast\n# This file is managed by Docker setup\nOptions -Indexes\n";
            file_put_contents($htaccess, $content);
            echo "📝 Created {$htaccess}\n";
        }

        // Create gitkeep files for empty directories
        $emptyDirs = [
            'web/app/uploads',
            'logs',
            'docker/mariadb/init'
        ];

        foreach ($emptyDirs as $dir) {
            $gitkeep = $dir . '/.gitkeep';
            if (!file_exists($gitkeep)) {
                touch($gitkeep);
                echo "📝 Created {$gitkeep}\n";
            }
        }
    }

    private function displayInstructions()
    {
        echo "\n" . str_repeat("=", 70) . "\n";
        echo "🎉 WordPress 6.5 + PHP 8.2 + MariaDB Setup Complete!\n";
        echo str_repeat("=", 70) . "\n";
        
        // Check if .env exists and show current configuration
        if (file_exists('.env')) {
            $env = file_get_contents('.env');
            preg_match('/WP_HOME=(.*)/', $env, $homeMatch);
            preg_match('/WEB_PORT=(\d+)/', $env, $portMatch);
            
            $home = $homeMatch[1] ?? 'http://localhost:8080';
            $port = $portMatch[1] ?? '8080';
        } else {
            $home = 'http://localhost:8080';
            $port = '8080';
        }

        echo "Next steps:\n\n";
        echo "1. Start the environment:\n";
        echo "   composer docker-up\n\n";
        echo "2. Visit your WordPress site:\n";
        echo "   {$home}\n\n";
        echo "3. Access development tools:\n";
        echo "   • phpMyAdmin: http://localhost:8081\n";
        echo "   • MailHog: http://localhost:8025\n";
        echo "   • MariaDB: localhost:3306\n";
        echo "   • Redis: localhost:6379\n\n";
        echo "Useful commands:\n";
        echo "   composer docker-down    # Stop containers\n";
        echo "   composer logs           # View logs\n";
        echo "   composer shell          # SSH into web container\n";
        echo "   composer wp             # Run WP-CLI commands\n";
        echo "   composer check-versions # Check PHP & WP versions\n";
        echo str_repeat("=", 70) . "\n";
        echo "🚀 Happy coding with WordPress 6.5, PHP 8.2, and MariaDB!\n";
    }
}

// Only run if called directly
if (basename(__FILE__) == basename($_SERVER['SCRIPT_NAME'])) {
   $setup = new DockerSetup();
    $setup->run();
}
