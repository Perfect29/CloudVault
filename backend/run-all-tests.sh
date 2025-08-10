#!/bin/bash

# CloudVault File Storage API - Comprehensive Test Runner
# Orchestrates all testing scenarios: unit tests, integration tests, endpoint tests, and performance tests

set -e

# Configuration
BASE_URL="http://localhost:8080"
RESULTS_DIR="test_results_$(date +%Y%m%d_%H%M%S)"
DOCKER_COMPOSE_FILE="docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TEST_SUITES=0
PASSED_TEST_SUITES=0
FAILED_TEST_SUITES=0

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

log_section() {
    echo -e "${PURPLE}[SECTION]${NC} $1"
}

log_test_suite() {
    echo -e "${CYAN}[TEST SUITE]${NC} $1"
}

increment_suite() {
    ((TOTAL_TEST_SUITES++))
}

suite_passed() {
    ((PASSED_TEST_SUITES++))
    log_success "Test suite passed: $1"
}

suite_failed() {
    ((FAILED_TEST_SUITES++))
    log_error "Test suite failed: $1"
}

# Check if Docker is available and services are running
check_docker_environment() {
    log_info "Checking Docker environment..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        return 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed or not in PATH"
        return 1
    fi
    
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log_error "Docker Compose file not found: $DOCKER_COMPOSE_FILE"
        return 1
    fi
    
    log_success "Docker environment is ready"
    return 0
}

# Start services using Docker Compose
start_services() {
    log_info "Starting services with Docker Compose..."
    
    # Stop any existing services
    docker-compose down --remove-orphans 2>/dev/null || true
    
    # Start services
    if docker-compose up -d; then
        log_success "Services started successfully"
        
        # Wait for services to be ready
        log_info "Waiting for services to be ready..."
        local max_attempts=30
        local attempt=1
        
        while [ $attempt -le $max_attempts ]; do
            if curl -s "$BASE_URL/health" > /dev/null 2>&1; then
                log_success "Services are ready!"
                return 0
            fi
            
            log_info "Attempt $attempt/$max_attempts - waiting for services..."
            sleep 2
            ((attempt++))
        done
        
        log_error "Services failed to become ready within $(($max_attempts * 2)) seconds"
        return 1
    else
        log_error "Failed to start services"
        return 1
    fi
}

# Stop services
stop_services() {
    log_info "Stopping services..."
    docker-compose down --remove-orphans 2>/dev/null || true
    log_success "Services stopped"
}

# Setup results directory
setup_results_dir() {
    mkdir -p "$RESULTS_DIR"
    log_info "Results will be saved to: $RESULTS_DIR"
    
    # Create subdirectories
    mkdir -p "$RESULTS_DIR/unit_tests"
    mkdir -p "$RESULTS_DIR/integration_tests"
    mkdir -p "$RESULTS_DIR/endpoint_tests"
    mkdir -p "$RESULTS_DIR/performance_tests"
}

# Run Maven unit tests
run_unit_tests() {
    log_test_suite "Running Maven Unit Tests"
    increment_suite
    
    local result_file="$RESULTS_DIR/unit_tests/maven_test_results.txt"
    
    if mvn test -Dtest="*Test" > "$result_file" 2>&1; then
        suite_passed "Maven Unit Tests"
        
        # Extract test summary
        grep -E "(Tests run:|BUILD SUCCESS|BUILD FAILURE)" "$result_file" > "$RESULTS_DIR/unit_tests/summary.txt" || true
        
        return 0
    else
        suite_failed "Maven Unit Tests"
        log_error "Check detailed results in: $result_file"
        return 1
    fi
}

# Run Maven integration tests
run_integration_tests() {
    log_test_suite "Running Maven Integration Tests"
    increment_suite
    
    local result_file="$RESULTS_DIR/integration_tests/maven_integration_results.txt"
    
    if mvn test -Dtest="*IntegrationTest" > "$result_file" 2>&1; then
        suite_passed "Maven Integration Tests"
        
        # Extract test summary
        grep -E "(Tests run:|BUILD SUCCESS|BUILD FAILURE)" "$result_file" > "$RESULTS_DIR/integration_tests/summary.txt" || true
        
        return 0
    else
        suite_failed "Maven Integration Tests"
        log_error "Check detailed results in: $result_file"
        return 1
    fi
}

# Run comprehensive test suite (all integration tests)
run_comprehensive_tests() {
    log_test_suite "Running Comprehensive Test Suite"
    increment_suite
    
    local result_file="$RESULTS_DIR/integration_tests/comprehensive_results.txt"
    
    if [ -f "run-comprehensive-tests.sh" ]; then
        if ./run-comprehensive-tests.sh > "$result_file" 2>&1; then
            suite_passed "Comprehensive Test Suite"
            return 0
        else
            suite_failed "Comprehensive Test Suite"
            log_error "Check detailed results in: $result_file"
            return 1
        fi
    else
        log_warning "Comprehensive test script not found, skipping"
        return 0
    fi
}

# Run endpoint tests
run_endpoint_tests() {
    log_test_suite "Running REST Endpoint Tests"
    increment_suite
    
    local result_file="$RESULTS_DIR/endpoint_tests/endpoint_test_results.txt"
    
    if [ -f "test-endpoints.sh" ]; then
        if ./test-endpoints.sh > "$result_file" 2>&1; then
            suite_passed "REST Endpoint Tests"
            return 0
        else
            suite_failed "REST Endpoint Tests"
            log_error "Check detailed results in: $result_file"
            return 1
        fi
    else
        log_error "Endpoint test script not found: test-endpoints.sh"
        suite_failed "REST Endpoint Tests"
        return 1
    fi
}

# Run performance tests
run_performance_tests() {
    log_test_suite "Running Performance Tests"
    increment_suite
    
    if [ -f "performance-test.sh" ]; then
        # Performance tests create their own results directory
        if ./performance-test.sh; then
            # Move performance results to our main results directory
            local perf_dir=$(ls -td performance_results_* 2>/dev/null | head -1)
            if [ -n "$perf_dir" ] && [ -d "$perf_dir" ]; then
                mv "$perf_dir"/* "$RESULTS_DIR/performance_tests/" 2>/dev/null || true
                rmdir "$perf_dir" 2>/dev/null || true
            fi
            
            suite_passed "Performance Tests"
            return 0
        else
            suite_failed "Performance Tests"
            return 1
        fi
    else
        log_warning "Performance test script not found: performance-test.sh"
        return 0
    fi
}

# Generate comprehensive HTML report
generate_comprehensive_report() {
    log_info "Generating comprehensive test report..."
    
    local html_file="$RESULTS_DIR/comprehensive_test_report.html"
    
    cat > "$html_file" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CloudVault API - Comprehensive Test Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 12px; box-shadow: 0 10px 30px rgba(0,0,0,0.2); overflow: hidden; }
        .header { background: linear-gradient(135deg, #2563EB 0%, #1d4ed8 100%); color: white; padding: 30px; text-align: center; }
        .header h1 { margin: 0; font-size: 2.5em; font-weight: 300; }
        .header p { margin: 10px 0 0 0; opacity: 0.9; }
        .content { padding: 30px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .summary-card { background: #f8fafc; border-radius: 8px; padding: 20px; text-align: center; border-left: 4px solid #2563EB; }
        .summary-card.success { border-left-color: #059669; }
        .summary-card.failure { border-left-color: #dc2626; }
        .summary-card.warning { border-left-color: #d97706; }
        .summary-card h3 { margin: 0 0 10px 0; color: #374151; }
        .summary-card .number { font-size: 2em; font-weight: bold; color: #1f2937; }
        .test-section { margin: 30px 0; }
        .test-section h2 { color: #1f2937; border-bottom: 3px solid #e5e7eb; padding-bottom: 10px; display: flex; align-items: center; }
        .test-section h2::before { content: ''; width: 4px; height: 20px; background: #2563EB; margin-right: 10px; }
        .test-result { background: #f9fafb; border-radius: 8px; padding: 20px; margin: 15px 0; border-left: 4px solid #6b7280; }
        .test-result.passed { border-left-color: #059669; }
        .test-result.failed { border-left-color: #dc2626; }
        .test-result.skipped { border-left-color: #d97706; }
        .test-result h4 { margin: 0 0 10px 0; color: #374151; }
        .test-result .status { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 0.8em; font-weight: bold; text-transform: uppercase; }
        .status.passed { background: #d1fae5; color: #065f46; }
        .status.failed { background: #fee2e2; color: #991b1b; }
        .status.skipped { background: #fef3c7; color: #92400e; }
        .footer { background: #f8fafc; padding: 20px; text-align: center; color: #6b7280; border-top: 1px solid #e5e7eb; }
        .details-link { color: #2563EB; text-decoration: none; font-weight: 500; }
        .details-link:hover { text-decoration: underline; }
        .timestamp { font-family: monospace; background: #f3f4f6; padding: 2px 6px; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>CloudVault API Test Report</h1>
            <p>Comprehensive Testing Results - $(date)</p>
        </div>
        
        <div class="content">
            <div class="summary">
                <div class="summary-card">
                    <h3>Total Test Suites</h3>
                    <div class="number">$TOTAL_TEST_SUITES</div>
                </div>
                <div class="summary-card success">
                    <h3>Passed</h3>
                    <div class="number">$PASSED_TEST_SUITES</div>
                </div>
                <div class="summary-card failure">
                    <h3>Failed</h3>
                    <div class="number">$FAILED_TEST_SUITES</div>
                </div>
                <div class="summary-card">
                    <h3>Success Rate</h3>
                    <div class="number">$(( TOTAL_TEST_SUITES > 0 ? (PASSED_TEST_SUITES * 100) / TOTAL_TEST_SUITES : 0 ))%</div>
                </div>
            </div>
EOF

    # Add test sections
    add_test_section_to_report() {
        local section_name="$1"
        local section_dir="$2"
        local section_id="$3"
        
        echo "            <div class='test-section'>" >> "$html_file"
        echo "                <h2>$section_name</h2>" >> "$html_file"
        
        if [ -d "$RESULTS_DIR/$section_dir" ]; then
            local has_results=false
            
            for result_file in "$RESULTS_DIR/$section_dir"/*.txt; do
                if [ -f "$result_file" ]; then
                    has_results=true
                    local filename=$(basename "$result_file")
                    local test_name="${filename%.*}"
                    
                    # Determine status based on file content or naming
                    local status="passed"
                    local status_class="passed"
                    
                    if grep -q -i "fail\|error\|exception" "$result_file" 2>/dev/null; then
                        status="failed"
                        status_class="failed"
                    elif grep -q -i "skip\|warn" "$result_file" 2>/dev/null; then
                        status="skipped"
                        status_class="skipped"
                    fi
                    
                    echo "                <div class='test-result $status_class'>" >> "$html_file"
                    echo "                    <h4>$test_name <span class='status $status_class'>$status</span></h4>" >> "$html_file"
                    echo "                    <p><a href='$section_dir/$filename' class='details-link'>View detailed results</a></p>" >> "$html_file"
                    echo "                </div>" >> "$html_file"
                fi
            done
            
            if [ "$has_results" = false ]; then
                echo "                <div class='test-result skipped'>" >> "$html_file"
                echo "                    <h4>No test results found <span class='status skipped'>skipped</span></h4>" >> "$html_file"
                echo "                </div>" >> "$html_file"
            fi
        else
            echo "                <div class='test-result skipped'>" >> "$html_file"
            echo "                    <h4>Test suite not executed <span class='status skipped'>skipped</span></h4>" >> "$html_file"
            echo "                </div>" >> "$html_file"
        fi
        
        echo "            </div>" >> "$html_file"
    }
    
    # Add all test sections
    add_test_section_to_report "Unit Tests" "unit_tests" "unit"
    add_test_section_to_report "Integration Tests" "integration_tests" "integration"
    add_test_section_to_report "Endpoint Tests" "endpoint_tests" "endpoint"
    add_test_section_to_report "Performance Tests" "performance_tests" "performance"
    
    cat >> "$html_file" << EOF
            
            <div class="test-section">
                <h2>Test Environment</h2>
                <div class="test-result">
                    <h4>Configuration</h4>
                    <p><strong>Base URL:</strong> $BASE_URL</p>
                    <p><strong>Docker Compose:</strong> $DOCKER_COMPOSE_FILE</p>
                    <p><strong>Test Execution:</strong> <span class="timestamp">$(date)</span></p>
                    <p><strong>Results Directory:</strong> $RESULTS_DIR</p>
                </div>
            </div>
        </div>
        
        <div class="footer">
            <p>Generated by CloudVault Comprehensive Test Suite</p>
            <p>For detailed logs and results, check the individual test result files</p>
        </div>
    </div>
</body>
</html>
EOF

    log_success "Comprehensive report generated: $html_file"
}

# Main execution
main() {
    echo "============================================================"
    echo "CloudVault File Storage API - Comprehensive Test Runner"
    echo "============================================================"
    echo ""
    
    # Setup
    setup_results_dir
    
    # Check environment
    if ! check_docker_environment; then
        log_error "Docker environment check failed"
        exit 1
    fi
    
    # Start services
    if ! start_services; then
        log_error "Failed to start services"
        exit 1
    fi
    
    # Trap to ensure cleanup
    trap 'stop_services' EXIT
    
    echo ""
    log_section "STARTING COMPREHENSIVE TEST EXECUTION"
    echo ""
    
    # Run all test suites
    log_section "1. UNIT TESTS"
    run_unit_tests || true
    
    echo ""
    log_section "2. INTEGRATION TESTS"
    run_integration_tests || true
    
    echo ""
    log_section "3. COMPREHENSIVE TESTS"
    run_comprehensive_tests || true
    
    echo ""
    log_section "4. ENDPOINT TESTS"
    run_endpoint_tests || true
    
    echo ""
    log_section "5. PERFORMANCE TESTS"
    run_performance_tests || true
    
    echo ""
    log_section "GENERATING REPORTS"
    generate_comprehensive_report
    
    echo ""
    echo "============================================================"
    echo "TEST EXECUTION SUMMARY"
    echo "============================================================"
    echo "Total Test Suites: $TOTAL_TEST_SUITES"
    echo -e "Passed: ${GREEN}$PASSED_TEST_SUITES${NC}"
    echo -e "Failed: ${RED}$FAILED_TEST_SUITES${NC}"
    echo "Success Rate: $(( TOTAL_TEST_SUITES > 0 ? (PASSED_TEST_SUITES * 100) / TOTAL_TEST_SUITES : 0 ))%"
    echo ""
    echo "Results Directory: $RESULTS_DIR"
    echo "Comprehensive Report: $RESULTS_DIR/comprehensive_test_report.html"
    echo ""
    
    if [ $FAILED_TEST_SUITES -eq 0 ]; then
        log_success "All test suites passed! 🎉"
        
        # Open report if possible
        if command -v xdg-open &> /dev/null; then
            xdg-open "$RESULTS_DIR/comprehensive_test_report.html" 2>/dev/null &
        elif command -v open &> /dev/null; then
            open "$RESULTS_DIR/comprehensive_test_report.html" 2>/dev/null &
        fi
        
        exit 0
    else
        log_error "Some test suites failed. Please review the detailed results."
        exit 1
    fi
}

# Execute main function
main "$@"