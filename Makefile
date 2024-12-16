.PHONY: up down restart init

up:
	docker compose up -d

down:
	docker compose down

restart: down up

init:
	docker compose up -d
	docker compose exec -u www-data php composer install
	docker compose exec -u www-data php npm install
	docker compose exec -u www-data php npm run build
	docker compose exec -u www-data php php artisan migrate --force
	docker compose exec -u www-data php php artisan migrate --env=testing --force

start: up
