#!/bin/bash

# CloudVault Docker Configuration Validator
# This script validates the Docker configuration files for syntax and completeness

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check if a file exists
check_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        print_success "$description exists: $file"
        return 0
    else
        print_error "$description missing: $file"
        return 1
    fi
}

# Function to validate YAML syntax (basic check)
validate_yaml() {
    local file="$1"
    local description="$2"
    
    if command -v python3 > /dev/null 2>&1; then
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            print_success "$description has valid YAML syntax"
            return 0
        else
            print_error "$description has invalid YAML syntax"
            return 1
        fi
    else
        print_warning "Python3 not available, skipping YAML validation for $description"
        return 0
    fi
}

# Function to check Docker Compose file structure
check_compose_structure() {
    local file="$1"
    local description="$2"
    
    print_status "Checking $description structure..."
    
    # Check for required sections
    local required_sections=("version" "services" "volumes" "networks")
    local errors=0
    
    for section in "${required_sections[@]}"; do
        if grep -q "^$section:" "$file"; then
            print_success "  ✓ $section section found"
        else
            print_error "  ✗ $section section missing"
            ((errors++))
        fi
    done
    
    # Check for specific services
    local required_services=("postgres" "redis" "backend" "frontend")
    for service in "${required_services[@]}"; do
        if grep -q "^  $service:" "$file"; then
            print_success "  ✓ $service service defined"
        else
            print_error "  ✗ $service service missing"
            ((errors++))
        fi
    done
    
    return $errors
}

# Function to check Dockerfile structure
check_dockerfile() {
    local file="$1"
    local description="$2"
    
    print_status "Checking $description structure..."
    
    local required_instructions=("FROM" "WORKDIR" "COPY" "EXPOSE")
    local errors=0
    
    for instruction in "${required_instructions[@]}"; do
        if grep -q "^$instruction" "$file"; then
            print_success "  ✓ $instruction instruction found"
        else
            print_warning "  ? $instruction instruction not found (may be optional)"
        fi
    done
    
    return $errors
}

# Function to check environment file
check_env_file() {
    local file="$1"
    local description="$2"
    
    print_status "Checking $description..."
    
    local required_vars=("DATABASE_URL" "JWT_SECRET" "STORAGE_TYPE" "CORS_ALLOWED_ORIGINS")
    local errors=0
    
    for var in "${required_vars[@]}"; do
        if grep -q "^$var=" "$file" || grep -q "^#.*$var=" "$file"; then
            print_success "  ✓ $var variable defined"
        else
            print_error "  ✗ $var variable missing"
            ((errors++))
        fi
    done
    
    return $errors
}

# Main validation function
main() {
    print_status "Starting CloudVault Docker configuration validation..."
    echo
    
    local total_errors=0
    
    # Check main Docker Compose files
    if check_file "docker-compose.yml" "Production Docker Compose"; then
        validate_yaml "docker-compose.yml" "Production Docker Compose"
        check_compose_structure "docker-compose.yml" "Production Docker Compose"
        ((total_errors += $?))
    else
        ((total_errors++))
    fi
    echo
    
    if check_file "docker-compose.dev.yml" "Development Docker Compose"; then
        validate_yaml "docker-compose.dev.yml" "Development Docker Compose"
        check_compose_structure "docker-compose.dev.yml" "Development Docker Compose"
        ((total_errors += $?))
    else
        ((total_errors++))
    fi
    echo
    
    # Check Dockerfiles
    if check_file "Dockerfile.frontend" "Frontend Dockerfile"; then
        check_dockerfile "Dockerfile.frontend" "Frontend Dockerfile"
        ((total_errors += $?))
    else
        ((total_errors++))
    fi
    echo
    
    if check_file "backend/Dockerfile" "Backend Production Dockerfile"; then
        check_dockerfile "backend/Dockerfile" "Backend Production Dockerfile"
        ((total_errors += $?))
    else
        ((total_errors++))
    fi
    echo
    
    if check_file "backend/Dockerfile.dev" "Backend Development Dockerfile"; then
        check_dockerfile "backend/Dockerfile.dev" "Backend Development Dockerfile"
        ((total_errors += $?))
    else
        ((total_errors++))
    fi
    echo
    
    # Check configuration files
    check_file "nginx/nginx.conf" "Nginx configuration"
    ((total_errors += $?))
    echo
    
    check_file "nginx/frontend.conf" "Frontend Nginx configuration"
    ((total_errors += $?))
    echo
    
    check_file "backend/init-db.sql" "Database initialization script"
    ((total_errors += $?))
    echo
    
    if check_file ".env.example" "Environment example file"; then
        check_env_file ".env.example" "Environment example file"
        ((total_errors += $?))
    else
        ((total_errors++))
    fi
    echo
    
    # Check scripts
    check_file "scripts/docker-dev.sh" "Development script (Linux/Mac)"
    ((total_errors += $?))
    echo
    
    check_file "scripts/docker-dev.bat" "Development script (Windows)"
    ((total_errors += $?))
    echo
    
    # Check documentation
    check_file "DOCKER_README.md" "Docker documentation"
    ((total_errors += $?))
    echo
    
    # Summary
    print_status "Validation Summary:"
    if [ $total_errors -eq 0 ]; then
        print_success "All Docker configuration files are present and appear to be valid!"
        print_status "You can now run: ./scripts/docker-dev.sh start"
    else
        print_error "Found $total_errors issues in Docker configuration"
        print_status "Please fix the issues above before running Docker"
        exit 1
    fi
}

# Run main function
main "$@"