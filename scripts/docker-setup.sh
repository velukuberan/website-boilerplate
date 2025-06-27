#!/bin/bash

# Docker setup script - runs after composer install
# Configures WordPress + Bedrock + MariaDB + Docker environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_info() {
    echo -e "${CYAN}$1${NC}"
}

print_section() {
    echo -e "${BLUE}$1${NC}"
}

# Load environment variables
load_env() {
    if [[ -f .env ]]; then
        # Load env vars, handling quotes properly
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ $key =~ ^[[:space:]]*# ]] && continue
            [[ -z $key ]] && continue
            
            # Remove quotes from value
            value="${value%\"}"
            value="${value#\"}"
            value="${value%\'}"
            value="${value#\'}"
            
            export "$key"="$value"
        done < .env
        return 0
    else
        return 1
    fi
}

# Create necessary directories
create_directories() {
    print_section "📁 Creating directory structure..."
    
    local directories=(
        "web/app/uploads"
        "web/app/themes"
        "web/app/plugins"
        "web/app/mu-plugins"
        "logs"
        "docker/mariadb/init"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            print_success "📁 Created directory: $dir"
        else
            print_info "📁 Directory already exists: $dir"
        fi
    done
    echo ""
}

# Set proper permissions
set_permissions() {
    print_section "🔐 Setting permissions..."
    
    # Skip on Windows (WSL detection)
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WSL_DISTRO_NAME" ]]; then
        print_info "🔐 Skipping permissions on Windows/WSL"
        echo ""
        return
    fi
    
    local paths=(
        "web/app/uploads:755"
        "logs:755"
        "scripts:755"
    )
    
    for path_perm in "${paths[@]}"; do
        IFS=':' read -r path permission <<< "$path_perm"
        if [[ -d "$path" ]]; then
            chmod "$permission" "$path"
            print_success "🔐 Set permissions $permission for $path"
        fi
    done
    
    # Make scripts executable
    if [[ -d "scripts" ]]; then
        find scripts -name "*.sh" -type f -exec chmod +x {} \;
        find scripts -name "*.php" -type f -exec chmod +x {} \;
        print_success "🔐 Made scripts executable"
    fi
    echo ""
}

# Create initialization files
create_init_files() {
    print_section "📝 Creating initialization files..."
    
    # Create WordPress index.php file (Bedrock's main entry point)
    local index_php="web/index.php"
    if [[ ! -f "$index_php" ]]; then
        cat > "$index_php" << 'EOF'
<?php

/**
 * WordPress view bootstrapper
 */
define('WP_USE_THEMES', true);
require __DIR__ . '/wp/wp-blog-header.php';
EOF
        print_success "📝 Created $index_php"
    else
        print_info "📝 File already exists: $index_php"
    fi
    
    # Create .htaccess for web directory
    local htaccess="web/.htaccess"
    if [[ ! -f "$htaccess" ]]; then
        cat > "$htaccess" << 'EOF'
# BEGIN WordPress
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
# END WordPress
EOF
        print_success "📝 Created $htaccess"
    else
        print_info "📝 File already exists: $htaccess"
    fi
    
    # Create gitkeep files for empty directories
    local empty_dirs=(
        "web/app/uploads"
        "logs"
        "docker/mariadb/init"
    )
    
    for dir in "${empty_dirs[@]}"; do
        local gitkeep="$dir/.gitkeep"
        if [[ ! -f "$gitkeep" ]]; then
            touch "$gitkeep"
            print_success "📝 Created $gitkeep"
        fi
    done
    echo ""
}

# Dsplay instructions
display_instructions() {
    echo ""
    echo "======================================================================"
    print_success "🎉 WordPress 6.5 + PHP 8.2 + MariaDB Setup Complete!"
    echo "======================================================================"
    echo ""
    
    # Load environment to get configuration
    load_env
    
    # Set defaults
    local home="${WP_HOME:-http://localhost:8080}"
    local web_port="${WEB_PORT:-8080}"
    local phpmyadmin_port="${PHPMYADMIN_PORT:-8081}"
    local mailhog_port="${MAILHOG_PORT:-8025}"
    local mysql_port="${MYSQL_PORT:-3306}"
    local redis_port="${REDIS_PORT:-6379}"
    
    print_section "Next steps:"
    echo ""
    echo "1. Start the environment:"
    print_info "   composer docker-up"
    echo ""
    echo "2. Visit your WordPress site:"
    print_info "   $home"
    echo ""
    echo "3. Access development tools:"
    print_info "   • phpMyAdmin: http://localhost:$phpmyadmin_port"
    print_info "   • MailHog: http://localhost:$mailhog_port"
    print_info "   • MariaDB: localhost:$mysql_port"
    print_info "   • Redis: localhost:$redis_port"
    echo ""
    print_section "Useful commands:"
    print_info "   composer docker-down     # Stop containers"
    print_info "   composer logs            # View logs"
    print_info "   composer shell           # SSH into web container"
    print_info "   composer wp              # Run WP-CLI commands"
    print_info "   composer check-versions  # Check PHP & WP versions"
    echo ""
    echo "======================================================================"
    print_success "🚀 Happy coding with WordPress 6.5, PHP 8.2, and MariaDB!"
    echo ""
}

# Main execution
main() {
    print_section "🐳 Setting up Docker environment with MariaDB..."
    echo ""
    
    create_directories
    set_permissions
    create_init_files
    display_instructions
}

# Run the main function
main "$@"
