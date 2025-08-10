#!/bin/bash

# CloudVault File Storage API - Comprehensive Endpoint Testing Script
# This script tests all REST endpoints with various scenarios

set -e

# Configuration
BASE_URL="http://localhost:8080"
TEST_USER="testuser_$(date +%s)"
TEST_EMAIL="test_$(date +%s)@example.com"
TEST_PASSWORD="password123"
JWT_TOKEN=""
FILE_ID=""
SHARE_LINK_ID=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_TESTS++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_TESTS++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

increment_test() {
    ((TOTAL_TESTS++))
}

# Test function wrapper
run_test() {
    local test_name="$1"
    local expected_status="$2"
    local curl_command="$3"
    
    increment_test
    log_info "Testing: $test_name"
    
    # Execute curl command and capture response
    response=$(eval "$curl_command" 2>/dev/null)
    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$status_code" = "$expected_status" ]; then
        log_success "$test_name - Status: $status_code"
        echo "$body" | jq . 2>/dev/null || echo "$body"
    else
        log_error "$test_name - Expected: $expected_status, Got: $status_code"
        echo "Response: $body"
    fi
    
    echo "----------------------------------------"
}

# Wait for service to be ready
wait_for_service() {
    log_info "Waiting for service to be ready..."
    for i in {1..30}; do
        if curl -s "$BASE_URL/health" > /dev/null 2>&1; then
            log_success "Service is ready!"
            return 0
        fi
        sleep 2
    done
    log_error "Service failed to start within 60 seconds"
    exit 1
}

# Create test file
create_test_file() {
    echo "This is a test file for CloudVault API testing." > test-file.txt
    echo "Binary content test" > test-binary.bin
    dd if=/dev/zero of=large-file.txt bs=1M count=101 2>/dev/null || true
}

# Cleanup test files
cleanup_test_files() {
    rm -f test-file.txt test-binary.bin large-file.txt
}

echo "=========================================="
echo "CloudVault API Comprehensive Testing"
echo "=========================================="

# Wait for service
wait_for_service

# Create test files
create_test_file

echo ""
echo "=== HEALTH ENDPOINT TESTS ==="

# Health endpoint tests
run_test "Health Check - GET /health" "200" \
    "curl -s -w '\n%{http_code}' '$BASE_URL/health'"

run_test "Health Check - POST method (should fail)" "405" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/health'"

run_test "Health Check - with headers" "200" \
    "curl -s -w '\n%{http_code}' -H 'User-Agent: Test-Agent' '$BASE_URL/health'"

echo ""
echo "=== AUTHENTICATION ENDPOINT TESTS ==="

# Auth endpoint tests - Signup
run_test "Signup - Valid data" "200" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/auth/signup' \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"$TEST_USER\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}'"

run_test "Signup - Duplicate username" "409" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/auth/signup' \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"$TEST_USER\",\"email\":\"different@example.com\",\"password\":\"$TEST_PASSWORD\"}'"

run_test "Signup - Duplicate email" "409" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/auth/signup' \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"different_user\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}'"

run_test "Signup - Invalid email format" "400" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/auth/signup' \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"newuser\",\"email\":\"invalid-email\",\"password\":\"$TEST_PASSWORD\"}'"

run_test "Signup - Short password" "400" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/auth/signup' \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"newuser2\",\"email\":\"new2@example.com\",\"password\":\"123\"}'"

run_test "Signup - Empty fields" "400" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/auth/signup' \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"\",\"email\":\"\",\"password\":\"\"}'"

run_test "Signup - Null fields" "400" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/auth/signup' \
    -H 'Content-Type: application/json' \
    -d '{\"username\":null,\"email\":null,\"password\":null}'"

run_test "Signup - Malformed JSON" "400" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/auth/signup' \
    -H 'Content-Type: application/json' \
    -d '{invalid json'"

# Auth endpoint tests - Signin
signin_response=$(curl -s -X POST "$BASE_URL/auth/signin" \
    -H 'Content-Type: application/json' \
    -d "{\"username\":\"$TEST_USER\",\"password\":\"$TEST_PASSWORD\"}")

JWT_TOKEN=$(echo "$signin_response" | jq -r '.token' 2>/dev/null || echo "")

run_test "Signin - Valid credentials" "200" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/auth/signin' \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"$TEST_USER\",\"password\":\"$TEST_PASSWORD\"}'"

run_test "Signin - Invalid username" "401" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/auth/signin' \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"nonexistent\",\"password\":\"$TEST_PASSWORD\"}'"

run_test "Signin - Invalid password" "401" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/auth/signin' \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"$TEST_USER\",\"password\":\"wrongpassword\"}'"

run_test "Signin - Empty credentials" "400" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/auth/signin' \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"\",\"password\":\"\"}'"

run_test "Signin - Case insensitive username" "200" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/auth/signin' \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"$(echo $TEST_USER | tr '[:lower:]' '[:upper:]')\",\"password\":\"$TEST_PASSWORD\"}'"

# Auth endpoint tests - Current user
if [ -n "$JWT_TOKEN" ] && [ "$JWT_TOKEN" != "null" ]; then
    run_test "Get current user - Valid token" "200" \
        "curl -s -w '\n%{http_code}' -H 'Authorization: Bearer $JWT_TOKEN' '$BASE_URL/auth/me'"
else
    log_warning "JWT token not available, skipping authenticated tests"
fi

run_test "Get current user - No token" "401" \
    "curl -s -w '\n%{http_code}' '$BASE_URL/auth/me'"

run_test "Get current user - Invalid token" "401" \
    "curl -s -w '\n%{http_code}' -H 'Authorization: Bearer invalid-token' '$BASE_URL/auth/me'"

run_test "Get current user - Malformed auth header" "401" \
    "curl -s -w '\n%{http_code}' -H 'Authorization: InvalidFormat' '$BASE_URL/auth/me'"

echo ""
echo "=== FILE ENDPOINT TESTS ==="

if [ -n "$JWT_TOKEN" ] && [ "$JWT_TOKEN" != "null" ]; then
    
    # File upload tests
    run_test "Upload file - Valid file" "200" \
        "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/files/upload' \
        -H 'Authorization: Bearer $JWT_TOKEN' \
        -F 'file=@test-file.txt'"
    
    # Get file ID from upload response for further tests
    upload_response=$(curl -s -X POST "$BASE_URL/files/upload" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -F 'file=@test-file.txt')
    FILE_ID=$(echo "$upload_response" | jq -r '.id' 2>/dev/null || echo "")
    
    run_test "Upload file - Empty file" "400" \
        "touch empty.txt && curl -s -w '\n%{http_code}' -X POST '$BASE_URL/files/upload' \
        -H 'Authorization: Bearer $JWT_TOKEN' \
        -F 'file=@empty.txt' && rm -f empty.txt"
    
    run_test "Upload file - Binary file" "200" \
        "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/files/upload' \
        -H 'Authorization: Bearer $JWT_TOKEN' \
        -F 'file=@test-binary.bin'"
    
    run_test "Upload file - Large file (>100MB)" "400" \
        "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/files/upload' \
        -H 'Authorization: Bearer $JWT_TOKEN' \
        -F 'file=@large-file.txt'"
    
    run_test "Upload file - No auth token" "401" \
        "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/files/upload' \
        -F 'file=@test-file.txt'"
    
    run_test "Upload file - Invalid token" "401" \
        "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/files/upload' \
        -H 'Authorization: Bearer invalid-token' \
        -F 'file=@test-file.txt'"
    
    # File listing tests
    run_test "Get user files - Default pagination" "200" \
        "curl -s -w '\n%{http_code}' -H 'Authorization: Bearer $JWT_TOKEN' '$BASE_URL/files'"
    
    run_test "Get user files - Custom pagination" "200" \
        "curl -s -w '\n%{http_code}' -H 'Authorization: Bearer $JWT_TOKEN' '$BASE_URL/files?page=0&size=5'"
    
    run_test "Get user files - With search" "200" \
        "curl -s -w '\n%{http_code}' -H 'Authorization: Bearer $JWT_TOKEN' '$BASE_URL/files?search=test'"
    
    run_test "Get user files - No auth token" "401" \
        "curl -s -w '\n%{http_code}' '$BASE_URL/files'"
    
    # File download tests
    if [ -n "$FILE_ID" ] && [ "$FILE_ID" != "null" ]; then
        run_test "Download file - Valid file ID" "200" \
            "curl -s -w '\n%{http_code}' -H 'Authorization: Bearer $JWT_TOKEN' '$BASE_URL/files/$FILE_ID/download'"
    fi
    
    run_test "Download file - Invalid file ID" "404" \
        "curl -s -w '\n%{http_code}' -H 'Authorization: Bearer $JWT_TOKEN' '$BASE_URL/files/nonexistent-id/download'"
    
    run_test "Download file - No auth token" "401" \
        "curl -s -w '\n%{http_code}' '$BASE_URL/files/some-id/download'"
    
    # Share link tests
    if [ -n "$FILE_ID" ] && [ "$FILE_ID" != "null" ]; then
        share_response=$(curl -s -X POST "$BASE_URL/files/$FILE_ID/share" \
            -H "Authorization: Bearer $JWT_TOKEN" \
            -d "expirationHours=24")
        SHARE_LINK_ID=$(echo "$share_response" | jq -r '.publicLinkId' 2>/dev/null || echo "")
        
        run_test "Create share link - Valid file with expiration" "200" \
            "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/files/$FILE_ID/share' \
            -H 'Authorization: Bearer $JWT_TOKEN' \
            -d 'expirationHours=24'"
        
        run_test "Create share link - Default expiration" "200" \
            "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/files/$FILE_ID/share' \
            -H 'Authorization: Bearer $JWT_TOKEN'"
        
        run_test "Create share link - Invalid expiration" "400" \
            "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/files/$FILE_ID/share' \
            -H 'Authorization: Bearer $JWT_TOKEN' \
            -d 'expirationHours=10000'"
    fi
    
    run_test "Create share link - Invalid file ID" "404" \
        "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/files/nonexistent-id/share' \
        -H 'Authorization: Bearer $JWT_TOKEN'"
    
    # Shared file download tests
    if [ -n "$SHARE_LINK_ID" ] && [ "$SHARE_LINK_ID" != "null" ]; then
        run_test "Download shared file - Valid link" "200" \
            "curl -s -w '\n%{http_code}' '$BASE_URL/files/share/$SHARE_LINK_ID'"
    fi
    
    run_test "Download shared file - Invalid link" "404" \
        "curl -s -w '\n%{http_code}' '$BASE_URL/files/share/nonexistent-link'"
    
    # File deletion tests
    if [ -n "$FILE_ID" ] && [ "$FILE_ID" != "null" ]; then
        run_test "Delete file - Valid file ID" "200" \
            "curl -s -w '\n%{http_code}' -X DELETE -H 'Authorization: Bearer $JWT_TOKEN' '$BASE_URL/files/$FILE_ID'"
    fi
    
    run_test "Delete file - Invalid file ID" "404" \
        "curl -s -w '\n%{http_code}' -X DELETE -H 'Authorization: Bearer $JWT_TOKEN' '$BASE_URL/files/nonexistent-id'"
    
    run_test "Delete file - No auth token" "401" \
        "curl -s -w '\n%{http_code}' -X DELETE '$BASE_URL/files/some-id'"
    
    # User stats tests
    run_test "Get user stats - Valid token" "200" \
        "curl -s -w '\n%{http_code}' -H 'Authorization: Bearer $JWT_TOKEN' '$BASE_URL/files/stats'"
    
    run_test "Get user stats - No auth token" "401" \
        "curl -s -w '\n%{http_code}' '$BASE_URL/files/stats'"

else
    log_warning "Skipping file endpoint tests - JWT token not available"
fi

echo ""
echo "=== EDGE CASE AND SECURITY TESTS ==="

# CORS tests
run_test "CORS - Preflight request" "200" \
    "curl -s -w '\n%{http_code}' -X OPTIONS '$BASE_URL/auth/signin' \
    -H 'Origin: http://localhost:3000' \
    -H 'Access-Control-Request-Method: POST' \
    -H 'Access-Control-Request-Headers: Content-Type'"

# Content-Type tests
run_test "Invalid Content-Type - XML" "415" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/auth/signin' \
    -H 'Content-Type: application/xml' \
    -d '<login><username>test</username></login>'"

# Large payload tests
run_test "Large JSON payload" "400" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/auth/signup' \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"$(printf 'a%.0s' {1..10000})\",\"email\":\"test@example.com\",\"password\":\"password123\"}'"

# SQL injection attempts
run_test "SQL Injection attempt in username" "401" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/auth/signin' \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"admin\\'; DROP TABLE users; --\",\"password\":\"password\"}'"

# XSS attempts
run_test "XSS attempt in signup" "400" \
    "curl -s -w '\n%{http_code}' -X POST '$BASE_URL/auth/signup' \
    -H 'Content-Type: application/json' \
    -d '{\"username\":\"<script>alert(\\\"xss\\\")</script>\",\"email\":\"xss@example.com\",\"password\":\"password123\"}'"

# Rate limiting tests (if implemented)
log_info "Testing rate limiting (sending 10 rapid requests)..."
for i in {1..10}; do
    curl -s "$BASE_URL/auth/signin" \
        -H 'Content-Type: application/json' \
        -d '{"username":"nonexistent","password":"wrong"}' > /dev/null &
done
wait

# Cleanup
cleanup_test_files

echo ""
echo "=========================================="
echo "TEST SUMMARY"
echo "=========================================="
echo "Total Tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review the output above.${NC}"
    exit 1
fi