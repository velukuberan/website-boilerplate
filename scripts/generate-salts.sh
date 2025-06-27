#!/bin/bash

# Generate WordPress salts and update .env file
# Part of WordPress Bedrock + MariaDB + Docker boilerplate

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
ENV_FILE=".env"
SALT_LENGTH=64

# WordPress salt keys
SALT_KEYS=(
    "AUTH_KEY"
    "SECURE_AUTH_KEY"
    "LOGGED_IN_KEY"
    "NONCE_KEY"
    "AUTH_SALT"
    "SECURE_AUTH_SALT"
    "LOGGED_IN_SALT"
    "NONCE_SALT"
)

# Helper functions
print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

print_info() {
    echo -e "${CYAN}$1${NC}"
}

print_section() {
    echo -e "${BLUE}$1${NC}"
}

# Generate a cryptographically secure salt
generate_salt() {
    local length=${1:-$SALT_LENGTH}
    local salt=""
    
    # Character set for salts (WordPress compatible)
    local chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?'
    local chars_len=${#chars}
    
    # Try different methods for generating random bytes
    if command -v openssl >/dev/null 2>&1; then
        # Method 1: Use OpenSSL (most secure)
        for ((i=0; i<length; i++)); do
            # Get a random byte and map it to our character set
            local random_byte=$(openssl rand -hex 1)
            local random_int=$((0x$random_byte))
            local char_index=$((random_int % chars_len))
            salt+="${chars:$char_index:1}"
        done
    elif [[ -r /dev/urandom ]]; then
        # Method 2: Use /dev/urandom (good security)
        for ((i=0; i<length; i++)); do
            local random_byte=$(od -An -N1 -tu1 < /dev/urandom | tr -d ' ')
            local char_index=$((random_byte % chars_len))
            salt+="${chars:$char_index:1}"
        done
    elif command -v shuf >/dev/null 2>&1; then
        # Method 3: Use shuf (fair security)
        for ((i=0; i<length; i++)); do
            local char_index=$(shuf -i 0-$((chars_len-1)) -n 1)
            salt+="${chars:$char_index:1}"
        done
    else
        # Method 4: Fallback using $RANDOM (least secure, but works everywhere)
        print_info "⚠️  Using fallback random generation (less secure)"
        for ((i=0; i<length; i++)); do
            local char_index=$((RANDOM % chars_len))
            salt+="${chars:$char_index:1}"
        done
    fi
    
    echo "$salt"
}

# Check if a salt key needs to be generated
needs_generation() {
    local key="$1"
    local env_content="$2"
    
    # Check if key is empty, has empty quotes, or has placeholder values
    if grep -q "^${key}=''$" <<< "$env_content" || \
       grep -q "^${key}=$" <<< "$env_content" || \
       grep -q "^${key}='generateme'$" <<< "$env_content" || \
       grep -q "^${key}=\"\"$" <<< "$env_content"; then
        return 0  # true - needs generation
    else
        return 1  # false - already has a value
    fi
}

# Update salt in .env content
update_salt_in_content() {
    local key="$1"
    local salt="$2"
    local content="$3"
    
    # Escape special characters for sed
    local escaped_salt=$(printf '%s\n' "$salt" | sed 's/[[\.*^$()+?{|]/\\&/g')
    
    # Replace the line with the new salt
    echo "$content" | sed "s/^${key}=.*$/${key}='${escaped_salt}'/"
}

# Main salt generation function
generate_wordpress_salts() {
    print_section "🔐 Generating WordPress security salts..."
    
    # Check if .env file exists
    if [[ ! -f "$ENV_FILE" ]]; then
        print_error "❌ .env file not found. Please run 'composer install' first."
        exit 1
    fi
    
    # Read current .env content
    local env_content=$(cat "$ENV_FILE")
    local needs_update=false
    local updated_content="$env_content"
    
    # Process each salt key
    for key in "${SALT_KEYS[@]}"; do
        if needs_generation "$key" "$env_content"; then
            print_info "🔑 Generating $key..."
            local salt=$(generate_salt)
            updated_content=$(update_salt_in_content "$key" "$salt" "$updated_conten")
            needs_update=true
            print_success "✅ Generated $key"
        else
            print_info "ℹ️  $key already configured"
        fi
    done
    
    # Update .env file if needed
    if [[ "$needs_update" == "true" ]]; then
        # Create backup
        cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Write updated content
        echo "$updated_content" > "$ENV_FILE"
        print_success "✅ WordPress salts updated in .env file"
        print_info "📄 Backup created: ${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    else
        print_info "ℹ️  WordPress salts already configured"
    fi
    
    echo ""
}

# Validate generated salts
validate_salts() {
    print_section "🔍 Validating generated salts..."
    
    local all_valid=true
    
    for key in "${SALT_KEYS[@]}"; do
        local salt_line=$(grep "^${key}=" "$ENV_FILE" || true)
        if [[ -n "$salt_line" ]]; then
            # Extract salt value (remove key= and quotes)
            local salt_value=$(echo "$salt_line" | sed "s/^${key}=//" | sed "s/^'//" | sed "s/'$//" | sed 's/^"//' | sed 's/"$//')
            
            if [[ ${#salt_value} -ge 32 ]]; then
                print_success "✅ $key: ${#salt_value} characters"
            else
                print_error "❌ $key: Too short (${#salt_value} characters)"
                all_valid=false
            fi
        else
            print_error "❌ $key: Not found"
            all_valid=false
        fi
    done
    
    if [[ "$all_valid" == "true" ]]; then
        print_success "🎉 All salts are valid!"
    else
        print_error "⚠️  Some salts may need regeneration"
        exit 1
    fi
    
    echo ""
}

# Force regenerate all salts
force_regenerate() {
    print_section "🔄 Force regenerating ALL WordPress salts..."
    
    if [[ ! -f "$ENV_FILE" ]]; then
        print_error "❌ .env file not found."
        exit 1
    fi
    
    local env_content=$(cat "$ENV_FILE")
    local updated_content="$env_content"
    
    # Create backup
    cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    print_info "📄 Backup created: ${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Generate new salts for all keys
    for key in "${SALT_KEYS[@]}"; do
        print_info "🔑 Regenerating $key..."
        local salt=$(generate_salt)
        updated_content=$(update_salt_in_content "$key" "$salt" "$updated_content")
        print_success "✅ Regenerated $key"
    done
    
    # Write updated content
    echo "$updated_content" > "$ENV_FILE"
    print_success "🎉 All WordPress salts regenerated!"
    
    echo ""
}

# Show usage help
show_help() {
    echo "WordPress Salt Generator"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -f, --force     Force regenerate all salts (even if they exist)"
    echo "  -v, --validate  Validate existing salts"
    echo "  -l, --length N  Set salt length (default: $SALT_LENGTH)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Generate missing salts"
    echo "  $0 --force            # Regenerate all salts"
    echo "  $0 --validate         # Check existing salts"
    echo "  $0 --length 128       # Use 128-character salts"
    echo ""
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--force)
                force_regenerate
                validate_salts
                exit 0
                ;;
            -v|--validate)
                validate_salts
                exit 0
                ;;
            -l|--length)
                if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                    SALT_LENGTH="$2"
                    shift
                else
                    print_error "❌ Invalid length: $2"
                    exit 1
                fi
                ;;
            *)
                print_error "❌ Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

# Main execution
main() {
    # Parse command line arguments
    parse_args "$@"
    
    # Default behavior: generate missing salts
    generate_wordpress_salts
    validate_salts
    
    print_success "🔐 Salt generation complete!"
}

# Run the main function
main "$@"
