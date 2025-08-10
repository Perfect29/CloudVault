#!/bin/bash

# CloudVault File Storage API - Performance Testing Script
# Tests API endpoints under load to identify performance bottlenecks

set -e

# Configuration
BASE_URL="http://localhost:8080"
TEST_USER="perftest_$(date +%s)"
TEST_EMAIL="perftest_$(date +%s)@example.com"
TEST_PASSWORD="password123"
JWT_TOKEN=""
RESULTS_DIR="performance_results_$(date +%Y%m%d_%H%M%S)"

# Test parameters
CONCURRENT_USERS=10
TOTAL_REQUESTS=100
TIMEOUT=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v ab &> /dev/null; then
        log_error "Apache Bench (ab) is not installed. Please install apache2-utils."
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        log_error "curl is not installed."
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_warning "jq is not installed. JSON parsing will be limited."
    fi
    
    log_success "All dependencies are available"
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

# Setup test user and get JWT token
setup_test_user() {
    log_info "Setting up test user..."
    
    # Create test user
    signup_response=$(curl -s -X POST "$BASE_URL/auth/signup" \
        -H 'Content-Type: application/json' \
        -d "{\"username\":\"$TEST_USER\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")
    
    if echo "$signup_response" | grep -q "User registered successfully"; then
        log_success "Test user created successfully"
    else
        log_error "Failed to create test user: $signup_response"
        exit 1
    fi
    
    # Get JWT token
    signin_response=$(curl -s -X POST "$BASE_URL/auth/signin" \
        -H 'Content-Type: application/json' \
        -d "{\"username\":\"$TEST_USER\",\"password\":\"$TEST_PASSWORD\"}")
    
    if command -v jq &> /dev/null; then
        JWT_TOKEN=$(echo "$signin_response" | jq -r '.token' 2>/dev/null || echo "")
    else
        JWT_TOKEN=$(echo "$signin_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    fi
    
    if [ -n "$JWT_TOKEN" ] && [ "$JWT_TOKEN" != "null" ]; then
        log_success "JWT token obtained"
    else
        log_error "Failed to obtain JWT token: $signin_response"
        exit 1
    fi
}

# Create test files for upload testing
create_test_files() {
    log_info "Creating test files..."
    
    # Small text file (1KB)
    head -c 1024 /dev/urandom | base64 > small_file.txt
    
    # Medium file (100KB)
    head -c 102400 /dev/urandom | base64 > medium_file.txt
    
    # Large file (1MB)
    head -c 1048576 /dev/urandom | base64 > large_file.txt
    
    log_success "Test files created"
}

# Cleanup test files
cleanup_test_files() {
    rm -f small_file.txt medium_file.txt large_file.txt
    rm -f auth_data.json upload_data.txt
}

# Create results directory
setup_results_dir() {
    mkdir -p "$RESULTS_DIR"
    log_info "Results will be saved to: $RESULTS_DIR"
}

# Performance test function
run_performance_test() {
    local test_name="$1"
    local url="$2"
    local method="$3"
    local headers="$4"
    local data_file="$5"
    
    log_info "Running performance test: $test_name"
    
    local ab_command="ab -n $TOTAL_REQUESTS -c $CONCURRENT_USERS -s $TIMEOUT"
    
    if [ -n "$headers" ]; then
        ab_command="$ab_command -H '$headers'"
    fi
    
    if [ "$method" = "POST" ] && [ -n "$data_file" ]; then
        ab_command="$ab_command -p '$data_file' -T 'application/json'"
    fi
    
    ab_command="$ab_command '$url'"
    
    # Run the test and save results
    local result_file="$RESULTS_DIR/${test_name// /_}.txt"
    eval "$ab_command" > "$result_file" 2>&1
    
    # Extract key metrics
    local requests_per_sec=$(grep "Requests per second" "$result_file" | awk '{print $4}')
    local mean_time=$(grep "Time per request" "$result_file" | head -1 | awk '{print $4}')
    local failed_requests=$(grep "Failed requests" "$result_file" | awk '{print $3}')
    
    echo "Test: $test_name" >> "$RESULTS_DIR/summary.txt"
    echo "  Requests per second: $requests_per_sec" >> "$RESULTS_DIR/summary.txt"
    echo "  Mean time per request: $mean_time ms" >> "$RESULTS_DIR/summary.txt"
    echo "  Failed requests: $failed_requests" >> "$RESULTS_DIR/summary.txt"
    echo "  Detailed results: $result_file" >> "$RESULTS_DIR/summary.txt"
    echo "" >> "$RESULTS_DIR/summary.txt"
    
    log_success "$test_name completed - RPS: $requests_per_sec, Mean: ${mean_time}ms, Failed: $failed_requests"
}

# Upload performance test (special handling for multipart)
run_upload_performance_test() {
    local test_name="$1"
    local file_path="$2"
    
    log_info "Running upload performance test: $test_name"
    
    local result_file="$RESULTS_DIR/${test_name// /_}.txt"
    local success_count=0
    local total_time=0
    local failed_count=0
    
    echo "Upload Performance Test: $test_name" > "$result_file"
    echo "File: $file_path" >> "$result_file"
    echo "Concurrent users: $CONCURRENT_USERS" >> "$result_file"
    echo "Total requests: $TOTAL_REQUESTS" >> "$result_file"
    echo "" >> "$result_file"
    
    # Run concurrent uploads
    for ((i=1; i<=TOTAL_REQUESTS; i++)); do
        {
            start_time=$(date +%s.%N)
            response=$(curl -s -w "%{http_code}" -X POST "$BASE_URL/files/upload" \
                -H "Authorization: Bearer $JWT_TOKEN" \
                -F "file=@$file_path" 2>/dev/null)
            end_time=$(date +%s.%N)
            
            duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
            status_code="${response: -3}"
            
            if [ "$status_code" = "200" ]; then
                ((success_count++))
                total_time=$(echo "$total_time + $duration" | bc -l 2>/dev/null || echo "$total_time")
            else
                ((failed_count++))
            fi
            
            echo "Request $i: Status $status_code, Time ${duration}s" >> "$result_file"
        } &
        
        # Limit concurrent processes
        if (( i % CONCURRENT_USERS == 0 )); then
            wait
        fi
    done
    
    wait # Wait for all background processes to complete
    
    # Calculate metrics
    local avg_time=0
    if [ $success_count -gt 0 ]; then
        avg_time=$(echo "scale=3; $total_time / $success_count" | bc -l 2>/dev/null || echo "0")
    fi
    
    local requests_per_sec=0
    if [ $(echo "$total_time > 0" | bc -l 2>/dev/null || echo "0") -eq 1 ]; then
        requests_per_sec=$(echo "scale=2; $success_count / $total_time" | bc -l 2>/dev/null || echo "0")
    fi
    
    echo "" >> "$result_file"
    echo "SUMMARY:" >> "$result_file"
    echo "Successful requests: $success_count" >> "$result_file"
    echo "Failed requests: $failed_count" >> "$result_file"
    echo "Average time per request: ${avg_time}s" >> "$result_file"
    echo "Requests per second: $requests_per_sec" >> "$result_file"
    
    # Add to summary
    echo "Test: $test_name" >> "$RESULTS_DIR/summary.txt"
    echo "  Requests per second: $requests_per_sec" >> "$RESULTS_DIR/summary.txt"
    echo "  Average time per request: ${avg_time}s" >> "$RESULTS_DIR/summary.txt"
    echo "  Failed requests: $failed_count" >> "$RESULTS_DIR/summary.txt"
    echo "  Detailed results: $result_file" >> "$RESULTS_DIR/summary.txt"
    echo "" >> "$RESULTS_DIR/summary.txt"
    
    log_success "$test_name completed - RPS: $requests_per_sec, Avg: ${avg_time}s, Failed: $failed_count"
}

# Generate HTML report
generate_html_report() {
    local html_file="$RESULTS_DIR/performance_report.html"
    
    cat > "$html_file" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CloudVault API Performance Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2563EB; text-align: center; }
        h2 { color: #1f2937; border-bottom: 2px solid #e5e7eb; padding-bottom: 10px; }
        .test-summary { background: #f8fafc; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .metric { display: inline-block; margin: 10px 20px 10px 0; }
        .metric-label { font-weight: bold; color: #374151; }
        .metric-value { color: #059669; font-size: 1.2em; }
        .failed { color: #dc2626; }
        .good { color: #059669; }
        .warning { color: #d97706; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #e5e7eb; }
        th { background-color: #f9fafb; font-weight: bold; }
        .footer { text-align: center; margin-top: 30px; color: #6b7280; }
    </style>
</head>
<body>
    <div class="container">
        <h1>CloudVault API Performance Test Report</h1>
        <p><strong>Test Date:</strong> $(date)</p>
        <p><strong>Base URL:</strong> $BASE_URL</p>
        <p><strong>Test Configuration:</strong> $TOTAL_REQUESTS requests, $CONCURRENT_USERS concurrent users</p>
        
        <h2>Test Summary</h2>
EOF

    # Add test results to HTML
    while IFS= read -r line; do
        if [[ $line == Test:* ]]; then
            echo "        <div class='test-summary'>" >> "$html_file"
            echo "            <h3>${line#Test: }</h3>" >> "$html_file"
        elif [[ $line == *"Requests per second:"* ]]; then
            rps=$(echo "$line" | awk '{print $4}')
            echo "            <div class='metric'><span class='metric-label'>Requests/sec:</span> <span class='metric-value'>$rps</span></div>" >> "$html_file"
        elif [[ $line == *"Mean time per request:"* ]] || [[ $line == *"Average time per request:"* ]]; then
            time=$(echo "$line" | awk '{print $5}')
            echo "            <div class='metric'><span class='metric-label'>Avg Response Time:</span> <span class='metric-value'>$time</span></div>" >> "$html_file"
        elif [[ $line == *"Failed requests:"* ]]; then
            failed=$(echo "$line" | awk '{print $3}')
            class="good"
            if [ "$failed" -gt 0 ]; then
                class="failed"
            fi
            echo "            <div class='metric'><span class='metric-label'>Failed:</span> <span class='metric-value $class'>$failed</span></div>" >> "$html_file"
        elif [[ $line == "" ]]; then
            echo "        </div>" >> "$html_file"
        fi
    done < "$RESULTS_DIR/summary.txt"

    cat >> "$html_file" << EOF
        
        <h2>Performance Analysis</h2>
        <table>
            <tr>
                <th>Endpoint</th>
                <th>Requests/sec</th>
                <th>Avg Response Time</th>
                <th>Failed Requests</th>
                <th>Status</th>
            </tr>
EOF

    # Add performance analysis table
    current_test=""
    rps=""
    time=""
    failed=""
    
    while IFS= read -r line; do
        if [[ $line == Test:* ]]; then
            if [ -n "$current_test" ]; then
                status="good"
                if [ "$failed" -gt 0 ]; then
                    status="failed"
                elif [[ $rps =~ ^[0-9]+\.?[0-9]*$ ]] && (( $(echo "$rps < 10" | bc -l 2>/dev/null || echo "0") )); then
                    status="warning"
                fi
                echo "            <tr><td>$current_test</td><td>$rps</td><td>$time</td><td>$failed</td><td class='$status'>$(echo $status | tr '[:lower:]' '[:upper:]')</td></tr>" >> "$html_file"
            fi
            current_test="${line#Test: }"
        elif [[ $line == *"Requests per second:"* ]]; then
            rps=$(echo "$line" | awk '{print $4}')
        elif [[ $line == *"Mean time per request:"* ]] || [[ $line == *"Average time per request:"* ]]; then
            time=$(echo "$line" | awk '{print $5}')
        elif [[ $line == *"Failed requests:"* ]]; then
            failed=$(echo "$line" | awk '{print $3}')
        fi
    done < "$RESULTS_DIR/summary.txt"
    
    # Add last test
    if [ -n "$current_test" ]; then
        status="good"
        if [ "$failed" -gt 0 ]; then
            status="failed"
        elif [[ $rps =~ ^[0-9]+\.?[0-9]*$ ]] && (( $(echo "$rps < 10" | bc -l 2>/dev/null || echo "0") )); then
            status="warning"
        fi
        echo "            <tr><td>$current_test</td><td>$rps</td><td>$time</td><td>$failed</td><td class='$status'>$(echo $status | tr '[:lower:]' '[:upper:]')</td></tr>" >> "$html_file"
    fi

    cat >> "$html_file" << EOF
        </table>
        
        <h2>Recommendations</h2>
        <ul>
            <li><strong>Good Performance:</strong> >50 requests/sec, <200ms response time</li>
            <li><strong>Acceptable Performance:</strong> 10-50 requests/sec, 200-500ms response time</li>
            <li><strong>Poor Performance:</strong> <10 requests/sec, >500ms response time</li>
            <li><strong>Failed Requests:</strong> Should be 0 for production readiness</li>
        </ul>
        
        <div class="footer">
            <p>Generated by CloudVault Performance Testing Suite</p>
        </div>
    </div>
</body>
</html>
EOF

    log_success "HTML report generated: $html_file"
}

echo "=========================================="
echo "CloudVault API Performance Testing"
echo "=========================================="

# Check dependencies
check_dependencies

# Wait for service
wait_for_service

# Setup
setup_results_dir
setup_test_user
create_test_files

# Initialize summary file
echo "CloudVault API Performance Test Results" > "$RESULTS_DIR/summary.txt"
echo "Date: $(date)" >> "$RESULTS_DIR/summary.txt"
echo "Configuration: $TOTAL_REQUESTS requests, $CONCURRENT_USERS concurrent users" >> "$RESULTS_DIR/summary.txt"
echo "" >> "$RESULTS_DIR/summary.txt"

echo ""
echo "=== AUTHENTICATION PERFORMANCE TESTS ==="

# Create auth data file
cat > auth_data.json << EOF
{"username":"$TEST_USER","password":"$TEST_PASSWORD"}
EOF

# Authentication tests
run_performance_test "Health Check" "$BASE_URL/health" "GET" "" ""
run_performance_test "User Signin" "$BASE_URL/auth/signin" "POST" "" "auth_data.json"
run_performance_test "Get Current User" "$BASE_URL/auth/me" "GET" "Authorization: Bearer $JWT_TOKEN" ""

echo ""
echo "=== FILE MANAGEMENT PERFORMANCE TESTS ==="

# File management tests
run_performance_test "List User Files" "$BASE_URL/files" "GET" "Authorization: Bearer $JWT_TOKEN" ""
run_performance_test "Get User Stats" "$BASE_URL/files/stats" "GET" "Authorization: Bearer $JWT_TOKEN" ""

# Upload tests (special handling)
run_upload_performance_test "Upload Small File (1KB)" "small_file.txt"
run_upload_performance_test "Upload Medium File (100KB)" "medium_file.txt"

# Note: Large file upload test is commented out to avoid overwhelming the server
# run_upload_performance_test "Upload Large File (1MB)" "large_file.txt"

echo ""
echo "=== STRESS TESTS ==="

# Increase load for stress testing
ORIGINAL_REQUESTS=$TOTAL_REQUESTS
ORIGINAL_CONCURRENT=$CONCURRENT_USERS

TOTAL_REQUESTS=500
CONCURRENT_USERS=50

log_info "Running stress tests with $TOTAL_REQUESTS requests and $CONCURRENT_USERS concurrent users"

run_performance_test "Health Check Stress" "$BASE_URL/health" "GET" "" ""
run_performance_test "Authentication Stress" "$BASE_URL/auth/signin" "POST" "" "auth_data.json"

# Restore original values
TOTAL_REQUESTS=$ORIGINAL_REQUESTS
CONCURRENT_USERS=$ORIGINAL_CONCURRENT

echo ""
echo "=== GENERATING REPORTS ==="

# Generate HTML report
generate_html_report

# Cleanup
cleanup_test_files

echo ""
echo "=========================================="
echo "PERFORMANCE TEST COMPLETED"
echo "=========================================="
echo "Results directory: $RESULTS_DIR"
echo "Summary: $RESULTS_DIR/summary.txt"
echo "HTML Report: $RESULTS_DIR/performance_report.html"
echo ""

# Display summary
cat "$RESULTS_DIR/summary.txt"

log_success "Performance testing completed successfully!"

# Open HTML report if possible
if command -v xdg-open &> /dev/null; then
    xdg-open "$RESULTS_DIR/performance_report.html" 2>/dev/null &
elif command -v open &> /dev/null; then
    open "$RESULTS_DIR/performance_report.html" 2>/dev/null &
fi