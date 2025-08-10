@echo off
REM CloudVault Docker Development Scripts for Windows
REM This batch file provides convenient commands for managing the development environment

setlocal enabledelayedexpansion

set PROJECT_NAME=cloudvault

REM Function to print colored output (simplified for Windows)
:print_status
echo [INFO] %~1
goto :eof

:print_success
echo [SUCCESS] %~1
goto :eof

:print_warning
echo [WARNING] %~1
goto :eof

:print_error
echo [ERROR] %~1
goto :eof

REM Function to check if Docker is running
:check_docker
docker info >nul 2>&1
if errorlevel 1 (
    call :print_error "Docker is not running. Please start Docker and try again."
    exit /b 1
)
goto :eof

REM Function to check if Docker Compose is available
:check_docker_compose
docker-compose --version >nul 2>&1
if errorlevel 1 (
    call :print_error "Docker Compose is not installed. Please install Docker Compose and try again."
    exit /b 1
)
goto :eof

REM Function to start development environment
:start_dev
call :print_status "Starting CloudVault development environment..."
call :check_docker
call :check_docker_compose

REM Create .env file if it doesn't exist
if not exist .env (
    call :print_warning ".env file not found. Creating from .env.example..."
    copy .env.example .env
)

REM Start services
docker-compose -f docker-compose.dev.yml up -d

call :print_success "Development environment started!"
call :print_status "Services available at:"
echo   - Frontend: http://localhost:3000
echo   - Backend API: http://localhost:8080/api
echo   - PostgreSQL: localhost:5432
echo   - Redis: localhost:6379
echo.
call :print_status "To view logs: docker-dev.bat logs"
call :print_status "To stop: docker-dev.bat stop"
goto :eof

REM Function to start with admin tools
:start_with_tools
call :print_status "Starting CloudVault development environment with admin tools..."
call :check_docker
call :check_docker_compose

REM Create .env file if it doesn't exist
if not exist .env (
    call :print_warning ".env file not found. Creating from .env.example..."
    copy .env.example .env
)

REM Start services with tools profile
docker-compose -f docker-compose.dev.yml --profile tools up -d

call :print_success "Development environment with tools started!"
call :print_status "Services available at:"
echo   - Frontend: http://localhost:3000
echo   - Backend API: http://localhost:8080/api
echo   - PostgreSQL: localhost:5432
echo   - Redis: localhost:6379
echo   - pgAdmin: http://localhost:5050 (admin@cloudvault.com / admin123)
echo   - RedisInsight: http://localhost:8001
goto :eof

REM Function to stop development environment
:stop_dev
call :print_status "Stopping CloudVault development environment..."
docker-compose -f docker-compose.dev.yml down
call :print_success "Development environment stopped!"
goto :eof

REM Function to restart development environment
:restart_dev
call :print_status "Restarting CloudVault development environment..."
call :stop_dev
call :start_dev
goto :eof

REM Function to view logs
:show_logs
if "%~2"=="" (
    call :print_status "Showing logs for all services..."
    docker-compose -f docker-compose.dev.yml logs -f
) else (
    call :print_status "Showing logs for service: %~2"
    docker-compose -f docker-compose.dev.yml logs -f %~2
)
goto :eof

REM Function to show status
:status
call :print_status "CloudVault service status:"
docker-compose -f docker-compose.dev.yml ps
goto :eof

REM Function to show database info
:db_info
call :print_status "Database connection information:"
echo   Host: localhost
echo   Port: 5432
echo   Database: cloudvault
echo   Username: postgres
echo   Password: password
echo.
call :print_status "To connect via psql:"
echo   psql -h localhost -p 5432 -U postgres -d cloudvault
goto :eof

REM Function to show help
:show_help
echo CloudVault Docker Development Helper for Windows
echo.
echo Usage: %~nx0 ^<command^> [options]
echo.
echo Commands:
echo   start         Start development environment
echo   start-tools   Start with admin tools (pgAdmin, RedisInsight)
echo   stop          Stop development environment
echo   restart       Restart development environment
echo   logs [service] Show logs (optionally for specific service)
echo   status        Show service status
echo   db-info       Show database connection information
echo   help          Show this help message
echo.
echo Examples:
echo   %~nx0 start
echo   %~nx0 logs backend
echo   %~nx0 status
goto :eof

REM Main script logic
if "%~1"=="start" (
    call :start_dev
) else if "%~1"=="start-tools" (
    call :start_with_tools
) else if "%~1"=="stop" (
    call :stop_dev
) else if "%~1"=="restart" (
    call :restart_dev
) else if "%~1"=="logs" (
    call :show_logs %*
) else if "%~1"=="status" (
    call :status
) else if "%~1"=="db-info" (
    call :db_info
) else if "%~1"=="help" (
    call :show_help
) else if "%~1"=="--help" (
    call :show_help
) else if "%~1"=="-h" (
    call :show_help
) else if "%~1"=="" (
    call :print_error "No command specified."
    echo.
    call :show_help
) else (
    call :print_error "Unknown command: %~1"
    echo.
    call :show_help
)