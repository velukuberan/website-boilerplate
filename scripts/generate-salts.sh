#!/bin/bash

# Self-fixing permissions
if [[ ! -x "$0" ]] && [[ "$OSTYPE" != "msys" ]] && [[ "$OSTYPE" != "cygwin" ]] && [[ -z "$WSL_DISTRO_NAME" ]]; then
    chmod +x "$0" 2>/dev/null || true
fi

# Generate WordPress salts and update .env file
set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    
    # Character set for salts (WordPress compatible, but avoiding problematic chars for shell)
    local chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*()_+-=[]{}:,.<>?'
    local chars_len=${#chars}
    
    # Use OpenSSL if available (most secure)
    if command -v openssl >/dev/null 2>&1; then
        for ((i=0; i<length; i++)); do
            local random_byte=$(openssl rand -hex 1)
            local random_int=$((0x$random_byte))
            local char_index=$((random_int % chars_len))
            salt+="${chars:$char_index:1}"
        done
    elif [[ -r /dev/urandom ]]; then
        # Use /dev/urandom
        for ((i=0; i<length; i++)); do
            local random_byte=$(od -An -N1 -tu1 < /dev/urandom | tr -d ' ')
            local char_index=$((random_byte % chars_len))
            salt+="${chars:$char_index:1}"
        done
    else
        # Fallback using $RANDOM
        print_info "⚠️  Using fallback random generation"
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
    
    # Check if line exists and get its value
    local line=$(grep "^${key}=" "$ENV_FILE" 2>/dev/null || echo "")
    
    if [[ -z "$line" ]]; then
        return 0  # Key doesn't exist, needs generation
    fi
    
    # Extract value (everything after first =)
    local value=$(echo "$line" | cut -d'=' -f2- | sed "s/^['\"]//; s/['\"]$//")
    
    # Check if empty or placeholder
    if [[ -z "$value" ]] || [[ "$value" == "generateme" ]] || [[ ${#value} -lt 32 ]]; then
        return 0  # Needs generation
    fi
    
    return 1  # Has good value
}

# Update salt in .env file using a more robust method
update_env_salt() {
    local key="$1"
    local salt="$2"
    local temp_file=$(mktemp)
    
    # Read the .env file line by line and update the specific key
    while IFS= read -r line; do
        if [[ "$line" =~ ^${key}= ]]; then
            # Replace this line with new salt
            echo "${key}='${salt}'" >> "$temp_file"
        else
            # Keep other lines as-is
            echo "$line" >> "$temp_file"
        fi
    done < "$ENV_FILE"
    
    # Move temp file to replace original
    mv "$temp_file" "$ENV_FILE"
}

# Add salt if it doesn't exist in .env
add_env_salt() {
    local key="$1"
    local salt="$2"
    
    echo "${key}='${salt}'" >> "$ENV_FILE"
}

# Main salt generation function
generate_wordpress_salts() {
    print_section "🔐 Generating WordPress security salts..."
    
    # Check if .env file exists
    if [[ ! -f "$ENV_FILE" ]]; then
        print_error "❌ .env file not found. Please run 'composer install' first."
        exit 1
    fi
    
    # Create backup
    cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    
    local updated=false
    
    # Process each salt key
    for key in "${SALT_KEYS[@]}"; do
        if needs_generation "$key"; then
            print_info "🔑 Geerating $key..."
            local salt=$(generate_salt)
            
            # Check if key exists in file
            if grep -q "^${key}=" "$ENV_FILE"; then
                update_env_salt "$key" "$salt"
            else
                add_env_salt "$key" "$salt"
            fi
            
            updated=true
            print_success "✅ Generated $key"
        else
            print_info "ℹ️  $key already configured"
        fi
    done
    
    if [[ "$updated" == "true" ]]; then
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
        local line=$(grep "^${key}=" "$ENV_FILE" 2>/dev/null || echo "")
        if [[ -n "$line" ]]; then
            # Extract salt value
            local salt_value=$(echo "$line" | cut -d'=' -f2- | sed "s/^['\"]//; s/['\"]$//")
            
            if [[ ${#salt_value} -ge 32 ]]; then
                print_success "✅ $key: ${#salt_value} characters"
            else
                print_error "❌ $key: Too short (${#salt_value} characters)"
                all_valid=false
            fi
        else
            print_error "❌ $key: Not found in .env file"
            all_valid=false
        fi
    done
    
    if [[ "$all_valid" == "true" ]]; then
        print_success "🎉 All salts are valid!"
    else
        print_error "⚠️  Some salts may need regeneration"
        print_info "💡 Try: ./scripts/generate-salts.sh --force"
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
    
    # Create backup
    cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    print_info "📄 Backup created: ${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Generate new salts for all keys
    for key in "${SALT_KEYS[@]}"; do
        print_info "🔑 Regenerating $key..."
        local salt=$(generate_salt)
        
        if grep -q "^${key}=" "$ENV_FILE"; then
            update_env_salt "$key" "$salt"
        else
            add_env_salt "$key" "$salt"
        fi
        
        print_success "✅ Regenerated $key"
    done
    
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
    echo "  -r, --repair    Repair corrupted .env file"
    echo ""
    echo "Examples:"
    echo "  $0                    # Generate missing salts"
    echo "  $0 --force            # Regenerate all salts"
    echo "  $0 --validate         # Check existing salts"
    echo "  $0 --repair           # Fix corrupted .env"
    echo ""
}

# Repair corrupted .env file
repair_env() {
    print_section "🔧 Repairing corrupted .env file..."
    
    if [[ ! -f "$ENV_FILE" ]]; then
        print_error "❌ .env file not found."
        exit 1
    fi
    
    # Create backup
    cp "$ENV_FILE" "${ENV_FILE}.corrupted.$(date +%Y%m%d_%H%M%S)"
    
    # Try to restore from .env.example if available
    if [[ -f ".env.example" ]]; then
        print_info "🔄 Restoring from .env.example..."
        cp ".env.example" "$ENV_FILE"
        print_success "✅ Restored .env from .env.example"
        
        # Generate fresh salts
        force_regenerate
    else
        print_error "❌ No .env.example found to restore from"
        print_info "💡 Please manually fix your .env file or restore from backup"
        exit 1
    fi
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
            -r|--repair)
                repair_env
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
