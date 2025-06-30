#!/bin/sh
set -e

echo "🐳 Starting WordPress container..."

# Change to correct directory
cd /var/www/html/web

# Wait for database
echo "⏳ Waiting for database..."
attempt=0
while [ $attempt -lt 30 ]; do
    if wp db check --allow-root 2>/dev/null; then
        echo "✅ Database ready"
        break
    fi
    sleep 2
    attempt=$((attempt + 1))
done

# Install WordPress if not installed
if ! wp core is-installed --allow-root 2>/dev/null; then
    echo "📦 Installing WordPress..."
    wp core install \
        --url="$WP_HOME" \
        --title="${WP_TITLE:-My WordPress Site}" \
        --admin_user="${WP_ADMIN_USER:-admin}" \
        --admin_password="${WP_ADMIN_PASSWORD:-admin}" \
        --admin_email="${WP_ADMIN_EMAIL:-admin@example.com}" \
        --skip-email \
        --allow-root
    
    # Fix URLs for Bedrock
    wp option update siteurl "$WP_SITEURL" --allow-root
    wp rewrite structure "/%postname%/" --allow-root
    
    echo "✅ WordPress installed with admin/admin"
fi

echo "🚀 Starting web server..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
