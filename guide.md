# Fitness WS - Start Guide

This guide explains how to spin up the local development environment for the Fitness web service.

## Prerequisites
- [Docker](https://www.docker.com/get-started) and Docker Compose installed (for the database).
- [PHP](https://www.php.net/downloads) installed locally (for running the backend web service).

---

## 1. Start the Database
The project uses a MariaDB database containerized via Docker. The database schema is automatically initialized from `database.sql` the first time you run it.

Open a terminal in the project root and run:
```bash
docker compose up -d
```
*(The `-d` flag runs it in the background/detached mode).*

**Database Connection Credentials:**
- **Host**: `127.0.0.1` (or `localhost`)
- **Port**: `3306`
- **Database Name**: `fitness_db`
- **Username**: `fitness_user`
- **Password**: `s`
- **Root Password**: `root`

*(Your `lib/config.php` should use these credentials to connect to the database).*

---

## 2. Start the PHP Application
With the database running, you can now start the PHP backend.

Run PHP's built-in development web server from the project's root directory:
```bash
php -S localhost:8000
```

The application will now be accessible from your browser or API testing tools (like Postman or cURL) at:
**`http://localhost:8000`**

---

## 3. Stopping the Environment

- **To stop the PHP server**: go to the terminal running the PHP server and press `Ctrl+C`.
- **To stop the database container**: run `docker compose down`. This will securely stop and remove the container. Your data will persist locally inside the Docker volume `fitness_db_data` defined in the `docker-compose.yml`.