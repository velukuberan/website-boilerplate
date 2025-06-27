#!/bin/bash

# WordPress Bedrock Stack Version Checker
# Checks versions of all components in the stack

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emojis
CHECK="✅"
CROSS="❌" 
INFO="ℹ️"
WARN="⚠️"

# Helper functions
print_header() {
    echo ""
    echo "============================================================"
    echo "🔍 WordPress Bedrock Stack Version Check"
    echo "============================================================"
    echo ""
}

print_section() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "   ${GREEN}${CHECK} $1${NC}"
}

print_error() {
    echo -e "   ${RED}${CROSS} $1${NC}"
}

print_info() {
    echo -e "   ${CYAN}• $1${NC}"
}

print_footer() {
    echo ""
    echo "============================================================"
    echo -e "${GREEN}${CHECK} Version check complete!${NC}"
    echo ""
}

# Load environment variables
load_env() {
    if [[ -f .env ]]; then
        export $(grep -v '^#' .env | xargs)
        return 0
    else
        return 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Docker container is running
container_running() {
    docker-compose ps --services --filter "status=running" 2>/dev/null | grep -q "$1"
}

# Get JSON value using basic tools
get_json_value() {
    local file="$1"
    local key="$2"
    if [[ -f "$file" ]]; then
        grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" | cut -d'"' -f4
    fi
}

# Check PHP version and extensions
check_php() {
    print_section "🐘 PHP Version Check"
    
    if command_exists php; then
        local php_version=$(php -r "echo PHP_VERSION;")
        print_success "PHP Version: $php_version"
        
        # Check important extensions
        local extensions=("mysqli" "pdo_mysql" "gd" "zip" "intl" "mbstring" "opcache" "redis")
        local loaded_extensions=()
        
        for ext in "${extensions[@]}"; do
            if php -m | grep -q "^$ext$"; then
                loaded_extensions+=("$ext")
            fi
        done
        
        print_info "Extensions: $(IFS=', '; echo "${loaded_extensions[*]}")"
        print_info "Memory Limit: $(php -r "echo ini_get('memory_limit');")"
        print_info "Max Execution Time: $(php -r "echo ini_get('max_execution_time');")s"
    else
        print_error "PHP not found"
    fi
    echo ""
}

# Check WordPress version
check_wordpress() {
    print_section "🌐 WordPress Version Check"
    
    # Check from composer.lock
    if [[ -f composer.lock ]]; then
        local wp_version=$(grep -A 5 '"name": "johnpbloch/wordpress"' composer.lock | grep '"version"' | cut -d'"' -f4)
        if [[ -n "$wp_version" ]]; then
            print_success "Composer Version: $wp_version"
        else
            print_error "WordPress not found in composer.lock"
        fi
    else
        print_error "composer.lock not found"
    fi
    
    # Check installed version
    if [[ -f web/wp/wp-includes/version.php ]]; then
        local installed_version=$(grep "wp_version =" web/wp/wp-includes/version.php | cut -d"'" -f2)
        if [[ -n "$installed_version" ]]; then
            print_info "Installed Version: $installed_version"
        fi
    else
        print_info "WordPress core files not found"
    fi
    echo ""
}

# Check Bedrock version
check_bedrock() {
    print_section "🏗️ Bedrock Version Check"
    
    if [[ -f composer.lock ]]; then
        local bedrock_version=$(grep -A 5 '"name": "roots/bedrock"' composer.lock | grep '"version"' | cut -d'"' -f4)
        if [[ -n "$bedrock_version" ]]; then
            print_success "Bedrock Version: $bedrock_version"
        else
            print_error "Bedrock not found in composer.lock"
        fi
    else
        print_error "composer.lock not found"
    fi
    echo ""
}

# Check MariaDB connection and version
check_mariadb() {
    print_section "🗄️ MariaDB Connection est"
    
    if ! load_env; then
        print_error "Could not load .env file"
        echo ""
        return
    fi
    
    # Set default values
    DB_HOST=${DB_HOST:-mariadb}
    DB_NAME=${DB_NAME:-wordpress}
    DB_USER=${DB_USER:-wordpress}
    DB_PASSWORD=${DB_PASSWORD:-wordpress}
    
    if command_exists docker-compose && container_running "mariadb"; then
        # Try to connect using docker-compose exec
        local version_output=$(docker-compose exec -T mariadb mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
        
        if [[ $? -eq 0 && -n "$version_output" ]]; then
            print_success "Connected successfully"
            print_info "Version: $version_output"
            
            # Check charset
            local charset_output=$(docker-compose exec -T mariadb mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "SELECT @@character_set_server, @@collation_server;" 2>/dev/null | tail -n 1)
            if [[ -n "$charset_output" ]]; then
                print_info "Charset: $charset_output"
            fi
        else
            print_error "Connection failed - check your database configuration"
        fi
    elif command_exists mysql; then
        # Try direct MySQL connection
        if mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -e "SELECT VERSION();" 2>/dev/null; then
            print_success "Connected successfully"
        else
            print_error "Connection failed - database may not be running"
        fi
    else
        print_error "MariaDB container not running or mysql client not available"
        print_info "Start containers with: composer docker-up"
    fi
    echo ""
}

# Check Redis connection
check_redis() {
    print_section "🔄 Redis Connection Test"
    
    if command_exists docker-compose && container_running "redis"; then
        # Check Redis using docker-compose
        local redis_info=$(docker-compose exec -T redis redis-cli INFO server 2>/dev/null)
        
        if [[ $? -eq 0 ]]; then
            print_success "Connected successfully"
            
            # Extract version
            local redis_version=$(echo "$redis_info" | grep "redis_version:" | cut -d':' -f2 | tr -d '\r')
            if [[ -n "$redis_version" ]]; then
                print_info "Version: $redis_version"
            fi
            
            # Extract memory usage
            local memory_info=$(docker-compose exec -T redis redis-cli INFO memory 2>/dev/null | grep "used_memory_human:" | cut -d':' -f2 | tr -d '\r')
            if [[ -n "$memory_info" ]]; then
                print_info "Memory: $memory_info"
            fi
        else
            print_error "Connection failed"
        fi
    elif command_exists redis-cli; then
        # Try direct Redis connection
        if redis-cli ping >/dev/null 2>&1; then
            print_success "Connected successfully"
            local version=$(redis-cli INFO server | grep "redis_version:" | cut -d':' -f2)
            print_info "Version: $version"
        else
            print_error "Connection failed"
        fi
    else
        print_error "Redis container not running or redis-cli not available"
        print_info "Start containers with: composer docker-up"
    fi
    echo ""
}

# Check Docker and Docker Compose
check_docker() {
    print_section "🐳 Docker Environment"
    
    if command_exists docker; then
        local docker_version=$(docker --version | cut -d' ' -f3 | tr -d ',')
        print_success "Docker Version: $docker_version"
    else
        print_error "Docker not found"
    fi
    
    if command_exists docker-compose; then
        local compose_version=$(docker-compose --version | cut -d' ' -f3 | tr -d ',')
        print_success "Docker Compose Version: $compose_version"
        
        # Check running containers
        if [[ -f docker-compose.yml ]]; then
            print_info "Container Status:"
            docker-compose ps --format "table" 2>/dev/null || print_error "Failed to get container status"
        fi
    else
        print_error "Docker Compose not found"
    fi
    echo ""
}

# Check Composer
check_composer() {
    print_section "📦 Composer Dependencies"
    
    if command_exists composer; then
        local composer_version=$(composer --version | cut -d' ' -f3)
        print_success "Composer Version: $composer_version"
    else
        print_error "Composer not found"
    fi
    
    if [[ -f composer.json ]]; then
        local php_requirement=$(get_json_value "composer.json" "php")
        if [[ -n "$php_requirement" ]]; then
            print_info "PHP Requirement: $php_requirement"
        fi
        
        # Count dependencies
        if [[ -f composer.lock ]]; then
            local package_count=$(grep -c '"name":' composer.lock 2>/dev/null || echo "0")
            print_info "Total Packages: $package_count"
            print_success "Dependencies installed"
        else
            print_error "composer.lock not found - run 'composer install'"
        fi
    else
        print_error "composer.json not found"
    fi
    echo ""
}

# Check Node.js (if package.json exists)
check_node() {
    if [[ -f package.json ]]; then
        print_section "📦 Node.js Environment"
        
        if command_exists node; then
            local node_version=$(node --version)
            print_success "Node.js Version: $node_version"
        else
            print_error "Node.js not found"
        fi
        
        if command_exists npm; then
            local npm_version=$(npm --version)
            print_success "NPM Version: $npm_version"
        else
            print_error "NPM not found"
        fi
        
        # Check if node_modules exists
        if [[ -d node_modules ]]; then
            print_success "Node dependencies installed"
        else
            print_error "Node dependencies not installed - run 'npm install'"
        fi
        echo ""
    fi
}

# Main execution
main() {
    print_header
    
    check_php
    check_wordpress
    check_bedrock
    check_composer
    check_docker
    check_mariadb
    check_redis
    check_node
    
    print_footer
}

# Run the main function
main "$@"
