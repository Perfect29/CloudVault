@echo off
REM CloudVault - Quick Local Start Script for Windows

echo 🚀 Starting CloudVault locally with Docker...

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker is not running. Please start Docker first.
    pause
    exit /b 1
)

REM Check if docker-compose is available (try both old and new syntax)
set COMPOSE_CMD=
docker-compose --version >nul 2>&1
if %errorlevel% equ 0 (
    set COMPOSE_CMD=docker-compose
) else (
    docker compose version >nul 2>&1
    if %errorlevel% equ 0 (
        set COMPOSE_CMD=docker compose
    ) else (
        echo ❌ Docker Compose is not available. Please install Docker Compose.
        pause
        exit /b 1
    )
)

echo ✅ Docker is running
echo ✅ Docker Compose is available (%COMPOSE_CMD%)

REM Stop any existing containers
echo 🛑 Stopping existing containers...
%COMPOSE_CMD% down

REM Build and start all services
echo 🔨 Building and starting all services...
%COMPOSE_CMD% up --build

echo 🎉 CloudVault should be running at:
echo    Frontend: http://localhost:3000
echo    Backend API: http://localhost:8080
echo    Database: localhost:5432
echo.
echo Press Ctrl+C to stop all services
pause