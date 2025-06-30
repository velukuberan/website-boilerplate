FROM php:8.2-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
	nginx \
	supervisor \
	curl \
	zip \
	unzip \
	git \
	mariadb-client \
	imagemagick \
	imagemagick-dev \
	libpng-dev \
	libjpeg-turbo-dev \
	freetype-dev \
	libzip-dev \
	icu-dev \
	oniguruma-dev \
	libxml2-dev \
	autoconf \
	gcc \
	g++ \
	make \
	&& rm -rf /var/cache/apk/*

# Configure and install PHP extensions for WordPress + MariaDB
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
	&& docker-php-ext-install -j$(nproc) \
    	gd \
    	mysqli \
    	pdo_mysql \
    	zip \
    	intl \
    	mbstring \
    	opcache \
    	exif \
    	xml \
    	soap

# Install imagick
RUN pecl install imagick \
	&& docker-php-ext-enable imagick

# Install Redis extension
RUN pecl install redis \
	&& docker-php-ext-enable redis

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install WP-CLI
RUN curl -L -o /usr/local/bin/wp-cli.phar https://github.com/wp-cli/wp-cli/releases/download/v2.8.1/wp-cli-2.8.1.phar \
    && chmod +x /usr/local/bin/wp-cli.phar \
    && echo '#!/bin/sh' > /usr/local/bin/wp \
    && echo 'php /usr/local/bin/wp-cli.phar --allow-root "$@"' >> /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

# Create necessary directories
RUN mkdir -p /var/log/supervisor \
	&& mkdir -p /run/nginx \
	&& mkdir -p /var/log/nginx \
	&& mkdir -p /var/www/html

# Set working directory
WORKDIR /var/www/html

# Copy entry point
COPY docker/scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy configuration files
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/php/php.ini /usr/local/etc/php/conf.d/custom.ini

# Set proper ownership
RUN chown -R www-data:www-data /var/www/html \
	&& chown -R www-data:www-data /var/log/nginx \
	&& chown -R www-data:www-data /run/nginx

# Expose port
EXPOSE 80

# Start entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
