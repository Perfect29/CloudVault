#!/bin/bash

# CloudVault Docker Development Scripts
# This script provides convenient commands for managing the development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project name
PROJECT_NAME="cloudvault"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to check if Docker Compose is available
check_docker_compose() {
    if ! command -v docker-compose > /dev/null 2>&1; then
        print_error "Docker Compose is not installed. Please install Docker Compose and try again."
        exit 1
    fi
}

# Function to start development environment
start_dev() {
    print_status "Starting CloudVault development environment..."
    check_docker
    check_docker_compose
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        print_warning ".env file not found. Creating from .env.example..."
        cp .env.example .env
    fi
    
    # Start services
    docker-compose -f docker-compose.dev.yml up -d
    
    print_success "Development environment started!"
    print_status "Services available at:"
    echo "  - Frontend: http://localhost:3000"
    echo "  - Backend API: http://localhost:8080/api"
    echo "  - PostgreSQL: localhost:5432"
    echo "  - Redis: localhost:6379"
    echo ""
    print_status "To view logs: ./scripts/docker-dev.sh logs"
    print_status "To stop: ./scripts/docker-dev.sh stop"
}

# Function to start with admin tools
start_with_tools() {
    print_status "Starting CloudVault development environment with admin tools..."
    check_docker
    check_docker_compose
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        print_warning ".env file not found. Creating from .env.example..."
        cp .env.example .env
    fi
    
    # Start services with tools profile
    docker-compose -f docker-compose.dev.yml --profile tools up -d
    
    print_success "Development environment with tools started!"
    print_status "Services available at:"
    echo "  - Frontend: http://localhost:3000"
    echo "  - Backend API: http://localhost:8080/api"
    echo "  - PostgreSQL: localhost:5432"
    echo "  - Redis: localhost:6379"
    echo "  - pgAdmin: http://localhost:5050 (admin@cloudvault.com / admin123)"
    echo "  - RedisInsight: http://localhost:8001"
}

# Function to stop development environment
stop_dev() {
    print_status "Stopping CloudVault development environment..."
    docker-compose -f docker-compose.dev.yml down
    print_success "Development environment stopped!"
}

# Function to restart development environment
restart_dev() {
    print_status "Restarting CloudVault development environment..."
    stop_dev
    start_dev
}

# Function to view logs
show_logs() {
    if [ -z "$2" ]; then
        print_status "Showing logs for all services..."
        docker-compose -f docker-compose.dev.yml logs -f
    else
        print_status "Showing logs for service: $2"
        docker-compose -f docker-compose.dev.yml logs -f "$2"
    fi
}

# Function to clean up everything
clean() {
    print_warning "This will remove all containers, volumes, and images for CloudVault."
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleaning up CloudVault Docker environment..."
        docker-compose -f docker-compose.dev.yml down -v --rmi all
        docker system prune -f
        print_success "Cleanup completed!"
    else
        print_status "Cleanup cancelled."
    fi
}

# Function to rebuild services
rebuild() {
    print_status "Rebuilding CloudVault services..."
    docker-compose -f docker-compose.dev.yml build --no-cache
    print_success "Rebuild completed!"
}

# Function to show status
status() {
    print_status "CloudVault service status:"
    docker-compose -f docker-compose.dev.yml ps
}

# Function to execute command in container
exec_container() {
    if [ -z "$2" ]; then
        print_error "Please specify a service name."
        echo "Available services: frontend, backend, postgres, redis"
        exit 1
    fi
    
    service="$2"
    shift 2
    command="${@:-/bin/bash}"
    
    print_status "Executing command in $service container: $command"
    docker-compose -f docker-compose.dev.yml exec "$service" $command
}

# Function to show database info
db_info() {
    print_status "Database connection information:"
    echo "  Host: localhost"
    echo "  Port: 5432"
    echo "  Database: cloudvault"
    echo "  Username: postgres"
    echo "  Password: password"
    echo ""
    print_status "To connect via psql:"
    echo "  psql -h localhost -p 5432 -U postgres -d cloudvault"
}

# Function to backup database
backup_db() {
    timestamp=$(date +"%Y%m%d_%H%M%S")
    backup_file="backup_${timestamp}.sql"
    
    print_status "Creating database backup: $backup_file"
    docker-compose -f docker-compose.dev.yml exec postgres pg_dump -U postgres cloudvault > "$backup_file"
    print_success "Database backup created: $backup_file"
}

# Function to restore database
restore_db() {
    if [ -z "$2" ]; then
        print_error "Please specify backup file path."
        echo "Usage: ./scripts/docker-dev.sh restore <backup_file.sql>"
        exit 1
    fi
    
    backup_file="$2"
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    print_warning "This will replace the current database with the backup."
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Restoring database from: $backup_file"
        docker-compose -f docker-compose.dev.yml exec -T postgres psql -U postgres -d cloudvault < "$backup_file"
        print_success "Database restored successfully!"
    else
        print_status "Restore cancelled."
    fi
}

# Function to show help
show_help() {
    echo "CloudVault Docker Development Helper"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  start         Start development environment"
    echo "  start-tools   Start with admin tools (pgAdmin, RedisInsight)"
    echo "  stop          Stop development environment"
    echo "  restart       Restart development environment"
    echo "  logs [service] Show logs (optionally for specific service)"
    echo "  status        Show service status"
    echo "  clean         Remove all containers, volumes, and images"
    echo "  rebuild       Rebuild all services"
    echo "  exec <service> [command] Execute command in container"
    echo "  db-info       Show database connection information"
    echo "  backup        Create database backup"
    echo "  restore <file> Restore database from backup"
    echo "  help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 logs backend"
    echo "  $0 exec backend bash"
    echo "  $0 backup"
    echo "  $0 restore backup_20240101_120000.sql"
}

# Main script logic
case "$1" in
    start)
        start_dev
        ;;
    start-tools)
        start_with_tools
        ;;
    stop)
        stop_dev
        ;;
    restart)
        restart_dev
        ;;
    logs)
        show_logs "$@"
        ;;
    status)
        status
        ;;
    clean)
        clean
        ;;
    rebuild)
        rebuild
        ;;
    exec)
        exec_container "$@"
        ;;
    db-info)
        db_info
        ;;
    backup)
        backup_db
        ;;
    restore)
        restore_db "$@"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac