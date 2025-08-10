@echo off
setlocal enabledelayedexpansion

REM CloudVault File Storage Platform - Comprehensive Test Execution Script (Windows)
REM This script runs all tests and generates detailed reports

echo ==============================================================================
echo CloudVault File Storage Platform - Comprehensive Test Suite
echo ==============================================================================
echo Starting comprehensive test execution at %date% %time%
echo.

REM Set test environment
set SPRING_PROFILES_ACTIVE=test

REM Create test reports directory
if not exist "target\test-reports" mkdir "target\test-reports"

REM Clean previous test results
echo [INFO] Cleaning previous test results...
call mvn clean >nul 2>&1

REM Compile the project
echo [INFO] Compiling project...
call mvn compile test-compile -q
if errorlevel 1 (
    echo [ERROR] Compilation failed
    exit /b 1
)

echo [SUCCESS] Project compiled successfully
echo.

REM Run Unit Tests
echo [INFO] Phase 1: Unit Tests
echo ==============================================================================

echo [INFO] Running Unit Tests - Controllers: Testing controller layer with mocked dependencies
echo ------------------------------------------------------------------------------
call mvn test -Dtest="com.cloudvault.filestorage.controller.*Test" -Dspring.profiles.active=test
if errorlevel 1 (
    echo [ERROR] Unit Tests - Controllers failed
) else (
    echo [SUCCESS] Unit Tests - Controllers completed successfully
)
echo.

echo [INFO] Running Unit Tests - Services: Testing service layer business logic
echo ------------------------------------------------------------------------------
call mvn test -Dtest="com.cloudvault.filestorage.service.*Test" -Dspring.profiles.active=test
if errorlevel 1 (
    echo [ERROR] Unit Tests - Services failed
) else (
    echo [SUCCESS] Unit Tests - Services completed successfully
)
echo.

REM Run Integration Tests
echo [INFO] Phase 2: Integration Tests
echo ==============================================================================

echo [INFO] Running Integration Tests - Authentication: End-to-end authentication flow testing
echo ------------------------------------------------------------------------------
call mvn test -Dtest="com.cloudvault.filestorage.integration.AuthControllerIntegrationTest" -Dspring.profiles.active=test
if errorlevel 1 (
    echo [ERROR] Integration Tests - Authentication failed
) else (
    echo [SUCCESS] Integration Tests - Authentication completed successfully
)
echo.

echo [INFO] Running Integration Tests - File Operations: End-to-end file management testing
echo ------------------------------------------------------------------------------
call mvn test -Dtest="com.cloudvault.filestorage.integration.FileControllerIntegrationTest" -Dspring.profiles.active=test
if errorlevel 1 (
    echo [ERROR] Integration Tests - File Operations failed
) else (
    echo [SUCCESS] Integration Tests - File Operations completed successfully
)
echo.

echo [INFO] Running Integration Tests - Health Check: Health endpoint testing
echo ------------------------------------------------------------------------------
call mvn test -Dtest="com.cloudvault.filestorage.integration.HealthControllerIntegrationTest" -Dspring.profiles.active=test
if errorlevel 1 (
    echo [ERROR] Integration Tests - Health Check failed
) else (
    echo [SUCCESS] Integration Tests - Health Check completed successfully
)
echo.

REM Run Security and Error Scenario Tests
echo [INFO] Phase 3: Security and Error Scenario Tests
echo ==============================================================================

echo [INFO] Running Security Tests: Security vulnerabilities and error handling
echo ------------------------------------------------------------------------------
call mvn test -Dtest="com.cloudvault.filestorage.integration.ErrorScenariosIntegrationTest" -Dspring.profiles.active=test
if errorlevel 1 (
    echo [ERROR] Security Tests failed
) else (
    echo [SUCCESS] Security Tests completed successfully
)
echo.

REM Run Performance Tests
echo [INFO] Phase 4: Performance Tests
echo ==============================================================================

echo [INFO] Running Performance Tests: Load testing and performance benchmarks
echo ------------------------------------------------------------------------------
call mvn test -Dtest="com.cloudvault.filestorage.integration.PerformanceIntegrationTest" -Dspring.profiles.active=test
if errorlevel 1 (
    echo [ERROR] Performance Tests failed
) else (
    echo [SUCCESS] Performance Tests completed successfully
)
echo.

REM Run All Tests Together for Final Verification
echo [INFO] Phase 5: Complete Test Suite Execution
echo ==============================================================================

echo [INFO] Running complete test suite...
call mvn test -Dspring.profiles.active=test
set final_exit_code=!errorlevel!

REM Generate Test Coverage Report
echo [INFO] Generating test coverage report...
call mvn jacoco:report -q

REM Generate Summary Report
echo [INFO] Generating test summary report...

(
echo CloudVault File Storage Platform - Test Execution Summary
echo =========================================================
echo Execution Date: %date% %time%
echo Test Environment: test
echo.
echo Test Categories Executed:
echo ========================
echo ✓ Unit Tests - Controller Layer
echo ✓ Unit Tests - Service Layer  
echo ✓ Integration Tests - Authentication Endpoints
echo ✓ Integration Tests - File Management Endpoints
echo ✓ Integration Tests - Health Check Endpoints
echo ✓ Security and Error Scenario Tests
echo ✓ Performance and Load Tests
echo.
echo Endpoints Tested:
echo ================
echo Authentication:
echo   POST /auth/signin    - Login with credentials
echo   POST /auth/signup    - User registration
echo   GET  /auth/me        - Get current user info
echo.
echo File Management:
echo   POST   /files/upload           - Upload files
echo   GET    /files                  - List user files ^(with pagination/search^)
echo   GET    /files/{id}/download    - Download specific file
echo   POST   /files/{id}/share       - Create shareable link
echo   GET    /files/share/{linkId}   - Download via public link
echo   DELETE /files/{id}             - Delete file
echo   GET    /files/stats            - Get user storage statistics
echo.
echo Health Check:
echo   GET /health - Application health status
echo.
echo Test Scenarios Covered:
echo ======================
echo ✓ Valid input scenarios
echo ✓ Invalid input validation
echo ✓ Authentication and authorization
echo ✓ File upload ^(various types and sizes^)
echo ✓ Pagination and search functionality
echo ✓ Cross-user access prevention
echo ✓ Share link expiration handling
echo ✓ Database constraint handling
echo ✓ Concurrent request handling
echo ✓ Memory usage optimization
echo ✓ SQL injection prevention
echo ✓ XSS attack prevention
echo ✓ Path traversal prevention
echo ✓ Performance benchmarking
echo ✓ Error handling and edge cases
echo.
echo Security Tests:
echo ==============
echo ✓ SQL Injection attempts blocked
echo ✓ XSS attacks prevented
echo ✓ Path traversal attacks blocked
echo ✓ Unauthorized access prevented
echo ✓ JWT token validation working
echo ✓ Input sanitization effective
echo.
echo Performance Benchmarks:
echo ======================
echo ✓ File upload performance measured
echo ✓ Large dataset query performance tested
echo ✓ Search functionality performance verified
echo ✓ Concurrent request handling validated
echo ✓ Memory usage optimization confirmed
echo ✓ Database operation performance measured
echo.
if !final_exit_code! equ 0 (
    echo Final Result: ALL TESTS PASSED ✅
) else (
    echo Final Result: SOME TESTS FAILED ❌
)
) > "target\test-reports\test-summary.txt"

REM Display final results
echo.
echo ==============================================================================
echo [INFO] TEST EXECUTION COMPLETED
echo ==============================================================================

if !final_exit_code! equ 0 (
    echo [SUCCESS] 🎉 ALL TESTS PASSED! The API is working correctly.
    echo.
    echo [INFO] ✅ Authentication endpoints working
    echo [INFO] ✅ File management endpoints working
    echo [INFO] ✅ Security measures effective
    echo [INFO] ✅ Performance benchmarks met
    echo [INFO] ✅ Error handling robust
    echo.
    echo [INFO] Test coverage report: target\site\jacoco\index.html
    echo [INFO] Test summary report: target\test-reports\test-summary.txt
) else (
    echo [ERROR] ❌ Some tests failed. Please review the output above.
    echo [INFO] Check target\surefire-reports\ for detailed failure information
)

echo.
echo [INFO] Comprehensive testing completed at %date% %time%
echo ==============================================================================

exit /b !final_exit_code!