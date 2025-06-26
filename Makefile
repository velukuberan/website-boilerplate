# WordPress Bedrock Docker Makefile with MariaDB
# Alternative to composer scripts for those who prefer make

.PHONY: help install up down build logs shell wp clean restart status

# Default target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install dependencies and setup environment
	composer install

up: ## Start the Docker environment
	docker-compose up -d

down: ## Stop the Docker environment
	docker-compose down

build: ## Build/rebuild Docker containers
	docker-compose build --no-cache

logs: ## Show Docker logs
	docker-compose logs -f

shell: ## Access the web container shell
	docker-compose exec web sh

wp: ## Run WP-CLI commands (usage: make wp ARGS="plugin list")
	docker-compose exec web wp $(ARGS)

clean: ## Clean up Docker containers and volumes
	docker-compose down -v
	docker system prune -f

restart: down up ## Restart the environment

status: ## Show container status
	docker-compose ps

# Database operations
db-export: ## Export database
	docker-compose exec web wp db export - > backup-$$(date +%Y%m%d-%H%M%S).sql

db-import: ## Import database (usage: make db-import FILE=backup.sql)
	docker-compose exec -T web wp db import - < $(FILE)

db-shell: ## Access MariaDB shell
	docker-compose exec mariadb mysql -u wordpress -pwordpress wordpress

# Development helpers
fresh-install: ## Fresh WordPress installation
	make down
	make clean
	make install
	make up
	@echo "Waiting for services to start..."
	sleep 10
	docker-compose exec web wp core install \
		--url=http://localhost:8080 \
		--title="WordPress Site" \
		--admin_user=admin \
		--admin_password=admin \
		--admin_email=admin@example.com \
		--skip-email

update: ## Update WordPress and plugins
	docker-compose exec web wp core update
	docker-compose exec web wp plugin update --all
	docker-compose exec web wp theme update --all

# Security
security-check: ## Run security checks
	docker-compose exec web wp core verify-checksums
	docker-compose exec web wp plugin verify-checksums --all

# Performance
optimize: ## Optimize database
	docker-compose exec web wp db optimize

flush-cache: ## Flush all caches
	docker-compose exec web wp cache flush
	docker-compose exec web wp rewrite flush
