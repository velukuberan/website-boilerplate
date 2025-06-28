# WordPress Bedrock Docker Boilerplate v4

A modern WordPress development environment using **Bedrock**, **Docker**, **WordPress 6.5**, **PHP 8.2**, and **MariaDB 11.4** with automated setup.

## Features

- 🚀 **WordPress 6.5** - Latest WordPress with enhanced security
- ⚡ **PHP 8.2** - Modern PHP with improved performance
- 🗄️ **MariaDB 11.4** - High-performance MySQL alternative
- 🏗️ **Bedrock** - Modern WordPress boilerplate with Composer
- 🐳 **Docker** - Containerized development environment
- 🔧 **Auto-setup** - Everything configured with `composer install`
- 📦 **Composer Scripts** - Convenient commands for common tasks
- 🛡️ **Enhanced Security** - Security headers and configurations
- 🔄 **Redis** - Object caching support
- 📧 **MailHog** - Email testing and debugging
- 📊 **phpMyAdmin** - Database management interface
- 🎯 **WP-CLI** - Command-line WordPress management

## Quick Start

```bash
git clone https://github.com/your-username/wordpress-boilerplate.git my-project
cd my-project
composer install
composer setup
composer docker-build
```

That's it! The setup script will automatically:
- ✅ Install WordPress 6.5 and all dependencies
- ✅ Copy `.env.example` to `.env`
- ✅ Generate WordPress security salts
- ✅ Create necessary directories
- ✅ Set proper permissions
- ✅ Display next steps

## Usage

### Start Development Environment
```bash
composer docker-up
```

### Stop Environment
```bash
composer docker-down
```

### View Logs
```bash
composer logs
```

### Access Container Shell
```bash
composer shell
```

### Run WP-CLI Commands
```bash
composer wp -- plugin list
composer wp -- user create admin admin@example.com --role=administrator
composer wp -- search-replace 'old-domain.com' 'new-domain.com'
```

### Check Versions
```bash
composer check-versions
```

### Rebuild Containers
```bash
composer docker-build
```

## Services & Access Points

| Service | URL | Port | Credentials |
|---------|-----|------|-------------|
| **WordPress** | http://localhost:8080 | 8080 | Set during WP installation |
| **phpMyAdmin** | http://localhost:8081 | 8081 | wordpress/wordpress |
| **MailHog** | http://localhost:8025 | 8025 | No login required |
| **MariaDB** | localhost:3306 | 3306 | wordpress/wordpress |
| **Redis** | localhost:6379 | 6379 | No auth |

## Project Structure

```
wordpress-boilerplate/
├── web/                      # WordPress web root
│   ├── app/                 # WordPress content directory
│   │   ├── plugins/         # Plugins
│   │   ├── themes/          # Themes
│   │   ├── mu-plugins/      # Must-use plugins
│   │   └── uploads/         # Media uploads
│   ├── wp/                  # WordPress core (auto-managed)
│   └── index.php           # WordPress bootstrap
├── docker/                  # Docker configuration
│   ├── web/                # Web server container config
│   ├── nginx/              # Nginx configuration
│   ├── php/                # PHP configuration
│   ├── mariadb/            # MariaDB configuration
│   └── supervisor/         # Process management
├── scripts/                # Setup automation scripts
│   ├── generate-salts.php  # WordPress salts generator
│   ├── docker-setup.php    # Environment setup
│   └── check-versions.php  # Version checker
├── logs/                   # Application logs
├── .env.example           # Environment template
├── .env                   # Your environment (auto-created)
├── composer.json          # Dependencies & scripts
├── docker-compose.yml     # Docker services definition
└── README.md              # This file
```

## Environment Configuration

Key environment variables in `.env`:

```bash
# Project Configuration
PROJECT_NAME=my-wordpress-project
DOMAIN=localhost
PORT=8080

# Database Configuration
DB_NAME=wordpress
DB_USER=wordpress
DB_PASSWORD=wordpress
DB_HOST=mariadb

# WordPress Configuration
WP_ENV=development
WP_HOME=http://localhost:8080
P_SITEURL=http://localhost:8080/wp

# Performance & Security
WP_CACHE=true
DISABLE_WP_CRON=false
AUTOMATIC_UPDATER_DISABLED=true
```

## Adding Plugins & Themes

### Via Composer (Recommended)
```bash
# Add a plugin from WordPress repository
composer require wpackagist-plugin/contact-form-7

# Add a premium plugin (if you have access)
composer require wpackagist-plugin/advanced-custom-fields-pro

# Add a theme
composer require wpackagist-theme/astra

# Update all dependencies
composer update
```

### Manual Installation
- Place plugins in `web/app/plugins/`
- Place themes in `web/app/themes/`
- Place must-use plugins in `web/app/mu-plugins/`

## Development Workflow

### 1. Initial Setup
```bash
git clone <your-boilerplate-repo> my-new-project
cd my-new-project
composer install
composer docker-build
composer docker-up
```

### 2. WordPress Installation
Visit http://localhost:8080 and complete the WordPress installation.

### 3. Development
- Edit themes/plugins in `web/app/`
- Access WordPress admin at http://localhost:8080/wp/wp-admin/
- Check emails at http://localhost:8025
- Manage database at http://localhost:8081

### 4. Version Control
```bash
git add .
git commit -m "Initial setup"
git push origin main
```

## MariaDB Benefits

This setup uses **MariaDB 11.4** instead of MySQL for several advantages:

- **Better Performance**: Generally 5-15% faster than MySQL
- **Enhanced Features**: More storage engines and advanced features
- **Active Development**: More frequent updates and improvements  
- **Better JSON Support**: Enhanced JSON functions and performance
- **Improved Security**: Additional security features and patches
- **Full Compatibility**: Drop-in replacement for MySQL
- **Open Source**: Truly open-source without commercial restrictions

## PHP 8.2 Benefits

- **Better Performance**: Up to 10% faster than PHP 8.1
- **Enhanced Security**: Latest security patches
- **New Features**: Readonly classes, disjunctive normal form types
- **Better Error Handling**: Improved debugging capabilities

## Troubleshooting

### Port Conflicts
If ports are in use, modify them in `.env`:
```bash
WEB_PORT=8090
MYSQL_PORT=3307
PHPMYADMIN_PORT=8082
```

### Permission Issues
```bash
sudo chown -R $USER:$USER .
composer docker-down && composer docker-up
```

### Clear Everything and Start Fresh
```bash
composer docker-down
docker system prune -a --volumes
composer docker-build
composer docker-up
```

### WordPress Installation Issues
```bash
composer wp -- core install \
  --url=http://localhost:8080 \
  --title="My Site" \
  --admin_user=admin \
  --admin_password=password \
  --admin_email=admin@example.com
```

### Database Connection Issues
Check your `.env` file and ensure:
- Database credentials are correct
- MariaDB container is running: `docker-compose ps`
- Network connectivity: `composer wp -- db check`

## Performance Optimization

### Built-in Optimizations
- **OPcache**: PHP bytecode caching enabled
- **Redis**: Object caching support
- **Gzip**: Compression enabled
- **Static file caching**: Long-term browser caching
- **Optimized MariaDB**: Performance-tuned configuration

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

---

**Happy coding with WordPress 6.5, PHP 8.2, and MariaDB! 🚀**
