.PHONY: up down build install migrate fresh test setup-test-db

# Start the application
up:
	docker compose up -d

# Stop the application
down:
	docker compose down

# Build containers
build:
	@echo "Setting up the project..."
	@if [ ! -f .env ]; then \
		cp .env.local .env; \
		echo "Created .env file from .env.local"; \
	fi
	docker compose build

# Install dependencies
install:
	docker compose exec app composer install
	docker compose exec app npm install

# Run migrations
migrate:
	docker compose exec app php artisan migrate

# Fresh migrations
fresh:
	docker compose exec app php artisan migrate:fresh

# Setup test database
setup-test-db:
	docker compose exec mysql mysql -uroot -psecret -e "CREATE DATABASE IF NOT EXISTS laravel_test;"
	docker compose exec app php artisan migrate --env=testing

# Run tests
test: setup-test-db
	docker compose exec app php artisan test --env=testing

# Setup project from scratch
setup: build up
	docker compose exec app composer install
	docker compose exec app npm install
	docker compose exec app php artisan key:generate
	docker compose exec app php artisan migrate
	@echo "Project setup completed!"

# Show logs
logs:
	docker compose logs -f

# Enter app container
shell:
	docker compose exec app bash

# Clear all caches
clear:
	docker compose exec app php artisan cache:clear
	docker compose exec app php artisan config:clear
	docker compose exec app php artisan route:clear
	docker compose exec app php artisan view:clear

# Start Vite development server
vite:
	docker compose exec app npm run dev
