#!/bin/bash

# CloudVault - Quick Local Start Script
echo "🚀 Starting CloudVault locally with Docker..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if docker-compose is available (try both old and new syntax)
COMPOSE_CMD=""
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "❌ Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

echo "✅ Docker is running"
echo "✅ Docker Compose is available ($COMPOSE_CMD)"

# Stop any existing containers
echo "🛑 Stopping existing containers..."
$COMPOSE_CMD down

# Build and start all services
echo "🔨 Building and starting all services..."
$COMPOSE_CMD up --build

echo "🎉 CloudVault should be running at:"
echo "   Frontend: http://localhost:3000"
echo "   Backend API: http://localhost:8080"
echo "   Database: localhost:5432"
echo ""
echo "Press Ctrl+C to stop all services"