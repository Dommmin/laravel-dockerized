# Laravel Application with Docker

This project is a fresh Laravel application configured to run with Docker.

## Getting Started

1. **Create your `.env` file**:
   ```bash
   cp .env.example .env
   ```

2. **Initialize the application**:
   For the first time setup, run:
   ```bash
   make init
   ```

3. **Start the application**:
   After the initial setup, you can use:
   ```bash
   make start
   ```
   or:
   ```bash
   make up
   ```

## Makefile Commands

The project includes a `Makefile` to simplify Docker commands. Below are the available commands:

### `make up`
Starts the Docker containers in detached mode.
```bash
make up
```

### `make down`
Stops and removes the Docker containers.
```bash
make down
```

### `make restart`
Restarts the Docker containers by running `down` followed by `up`.
```bash
make restart
```

### `make init`
Initializes the application by:
1. Starting the Docker containers.
2. Installing PHP dependencies using Composer.
3. Installing Node.js dependencies.
4. Building front-end assets.
5. Running database migrations (both for the default and testing environments).

```bash
make init
```

### `make start`
Starts the Docker containers. Equivalent to `make up`.
```bash
make start
```

## Notes
- Ensure Docker and Docker Compose are installed and running on your system.
- The `.env` file should be configured according to your environment before running `make init`.
- After running `make init`, you can access your application at the URL specified in your Docker Compose setup (usually `http://localhost`).

