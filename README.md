# Laravel Docker Development Environment

This repository contains a production-ready Docker setup for Laravel development, compatible with Symfony projects as well.

## Prerequisites

- Docker
- Docker Compose
- Make (optional, but recommended)

## Quick Start

1. Clone the repository:
```bash
git clone <repository-url>
cd <project-directory>
```

2. Run the setup command:
```bash
make setup
```

This will:
- Build all Docker containers
- Start the services
- Create .env file from .env.example
- Install Composer dependencies
- Install NPM dependencies
- Generate application key
- Run migrations

## Available Commands

- `make up` - Start all containers
- `make down` - Stop all containers
- `make build` - Rebuild containers
- `make install` - Install dependencies
- `make migrate` - Run database migrations
- `make fresh` - Fresh database migrations
- `make test` - Run tests
- `make logs` - View container logs
- `make shell` - Enter PHP container
- `make clear` - Clear all caches

## Services

- **PHP 8.4** - Application server (port 9000)
- **Nginx** - Web server (port 80)
- **MySQL 8.0** - Database (port 3306)
- **Redis** - Cache server (port 6379)
- **MySQL Test** - Test database (port 3307)

## Development

### File Permissions

The Docker setup is configured to match your local user's UID/GID. This ensures that files created inside the container have the correct permissions on your host system.

### Vite Development Server

The Vite development server is configured to work with Docker:
- Host: 0.0.0.0
- Port: 5173
- HMR enabled
- File watching with polling

### Running Tests

Tests are executed in a separate container with its own database:
```bash
make test
```

## Configuration Files

- `docker/php/php.ini` - PHP configuration
- `docker/nginx/conf.d/default.conf` - Nginx configuration
- `docker-compose.yml` - Docker services configuration
- `Dockerfile` - PHP container configuration

## Best Practices

1. Always run tests before committing:
```bash
make test
```

2. Clear caches when experiencing issues:
```bash
make clear
```

3. View logs for debugging:
```bash
make logs
```

## Troubleshooting

### Permission Issues

If you encounter permission issues:
1. Check your user's UID/GID:
```bash
id -u
id -g
```

2. Update the Dockerfile with your UID/GID if needed.

### Container Access

To access the PHP container:
```bash
make shell
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request 