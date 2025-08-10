@echo off
REM CloudVault File Storage API - Comprehensive Endpoint Testing Script (Windows)
REM This script tests all REST endpoints with various scenarios

setlocal enabledelayedexpansion

REM Configuration
set BASE_URL=http://localhost:8080
set TEST_USER=testuser_%RANDOM%
set TEST_EMAIL=test_%RANDOM%@example.com
set TEST_PASSWORD=password123
set JWT_TOKEN=
set FILE_ID=
set SHARE_LINK_ID=

REM Test counters
set TOTAL_TESTS=0
set PASSED_TESTS=0
set FAILED_TESTS=0

echo ==========================================
echo CloudVault API Comprehensive Testing
echo ==========================================

REM Check if curl is available
curl --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] curl is not available. Please install curl to run this test.
    exit /b 1
)

REM Check if jq is available (optional)
jq --version >nul 2>&1
if errorlevel 1 (
    echo [WARN] jq is not available. JSON responses will not be formatted.
    set HAS_JQ=false
) else (
    set HAS_JQ=true
)

echo.
echo [INFO] Waiting for service to be ready...
:wait_loop
curl -s "%BASE_URL%/health" >nul 2>&1
if errorlevel 1 (
    timeout /t 2 /nobreak >nul
    goto wait_loop
)
echo [PASS] Service is ready!

REM Create test files
echo This is a test file for CloudVault API testing. > test-file.txt
echo Binary content test > test-binary.bin

echo.
echo === HEALTH ENDPOINT TESTS ===

REM Health endpoint tests
echo [INFO] Testing: Health Check - GET /health
curl -s -w "%%{http_code}" "%BASE_URL%/health" > temp_response.txt
set /p response=<temp_response.txt
echo Response: !response!
set /a TOTAL_TESTS+=1

echo [INFO] Testing: Health Check - POST method (should fail)
curl -s -w "%%{http_code}" -X POST "%BASE_URL%/health" > temp_response.txt
set /p response=<temp_response.txt
echo Response: !response!
set /a TOTAL_TESTS+=1

echo.
echo === AUTHENTICATION ENDPOINT TESTS ===

REM Signup tests
echo [INFO] Testing: Signup - Valid data
curl -s -w "%%{http_code}" -X POST "%BASE_URL%/auth/signup" ^
    -H "Content-Type: application/json" ^
    -d "{\"username\":\"%TEST_USER%\",\"email\":\"%TEST_EMAIL%\",\"password\":\"%TEST_PASSWORD%\"}" > temp_response.txt
set /p response=<temp_response.txt
echo Response: !response!
set /a TOTAL_TESTS+=1

echo [INFO] Testing: Signup - Duplicate username
curl -s -w "%%{http_code}" -X POST "%BASE_URL%/auth/signup" ^
    -H "Content-Type: application/json" ^
    -d "{\"username\":\"%TEST_USER%\",\"email\":\"different@example.com\",\"password\":\"%TEST_PASSWORD%\"}" > temp_response.txt
set /p response=<temp_response.txt
echo Response: !response!
set /a TOTAL_TESTS+=1

echo [INFO] Testing: Signup - Invalid email format
curl -s -w "%%{http_code}" -X POST "%BASE_URL%/auth/signup" ^
    -H "Content-Type: application/json" ^
    -d "{\"username\":\"newuser\",\"email\":\"invalid-email\",\"password\":\"%TEST_PASSWORD%\"}" > temp_response.txt
set /p response=<temp_response.txt
echo Response: !response!
set /a TOTAL_TESTS+=1

echo [INFO] Testing: Signup - Short password
curl -s -w "%%{http_code}" -X POST "%BASE_URL%/auth/signup" ^
    -H "Content-Type: application/json" ^
    -d "{\"username\":\"newuser2\",\"email\":\"new2@example.com\",\"password\":\"123\"}" > temp_response.txt
set /p response=<temp_response.txt
echo Response: !response!
set /a TOTAL_TESTS+=1

echo [INFO] Testing: Signup - Empty fields
curl -s -w "%%{http_code}" -X POST "%BASE_URL%/auth/signup" ^
    -H "Content-Type: application/json" ^
    -d "{\"username\":\"\",\"email\":\"\",\"password\":\"\"}" > temp_response.txt
set /p response=<temp_response.txt
echo Response: !response!
set /a TOTAL_TESTS+=1

REM Signin tests
echo [INFO] Testing: Signin - Valid credentials
curl -s -X POST "%BASE_URL%/auth/signin" ^
    -H "Content-Type: application/json" ^
    -d "{\"username\":\"%TEST_USER%\",\"password\":\"%TEST_PASSWORD%\"}" > signin_response.txt

if "%HAS_JQ%"=="true" (
    for /f "delims=" %%i in ('jq -r .token signin_response.txt 2^>nul') do set JWT_TOKEN=%%i
)

curl -s -w "%%{http_code}" -X POST "%BASE_URL%/auth/signin" ^
    -H "Content-Type: application/json" ^
    -d "{\"username\":\"%TEST_USER%\",\"password\":\"%TEST_PASSWORD%\"}" > temp_response.txt
set /p response=<temp_response.txt
echo Response: !response!
set /a TOTAL_TESTS+=1

echo [INFO] Testing: Signin - Invalid username
curl -s -w "%%{http_code}" -X POST "%BASE_URL%/auth/signin" ^
    -H "Content-Type: application/json" ^
    -d "{\"username\":\"nonexistent\",\"password\":\"%TEST_PASSWORD%\"}" > temp_response.txt
set /p response=<temp_response.txt
echo Response: !response!
set /a TOTAL_TESTS+=1

echo [INFO] Testing: Signin - Invalid password
curl -s -w "%%{http_code}" -X POST "%BASE_URL%/auth/signin" ^
    -H "Content-Type: application/json" ^
    -d "{\"username\":\"%TEST_USER%\",\"password\":\"wrongpassword\"}" > temp_response.txt
set /p response=<temp_response.txt
echo Response: !response!
set /a TOTAL_TESTS+=1

REM Current user tests
if not "%JWT_TOKEN%"=="" if not "%JWT_TOKEN%"=="null" (
    echo [INFO] Testing: Get current user - Valid token
    curl -s -w "%%{http_code}" -H "Authorization: Bearer %JWT_TOKEN%" "%BASE_URL%/auth/me" > temp_response.txt
    set /p response=<temp_response.txt
    echo Response: !response!
    set /a TOTAL_TESTS+=1
) else (
    echo [WARN] JWT token not available, skipping authenticated tests
)

echo [INFO] Testing: Get current user - No token
curl -s -w "%%{http_code}" "%BASE_URL%/auth/me" > temp_response.txt
set /p response=<temp_response.txt
echo Response: !response!
set /a TOTAL_TESTS+=1

echo [INFO] Testing: Get current user - Invalid token
curl -s -w "%%{http_code}" -H "Authorization: Bearer invalid-token" "%BASE_URL%/auth/me" > temp_response.txt
set /p response=<temp_response.txt
echo Response: !response!
set /a TOTAL_TESTS+=1

echo.
echo === FILE ENDPOINT TESTS ===

if not "%JWT_TOKEN%"=="" if not "%JWT_TOKEN%"=="null" (
    
    echo [INFO] Testing: Upload file - Valid file
    curl -s -w "%%{http_code}" -X POST "%BASE_URL%/files/upload" ^
        -H "Authorization: Bearer %JWT_TOKEN%" ^
        -F "file=@test-file.txt" > temp_response.txt
    set /p response=<temp_response.txt
    echo Response: !response!
    set /a TOTAL_TESTS+=1
    
    REM Get file ID for further tests
    curl -s -X POST "%BASE_URL%/files/upload" ^
        -H "Authorization: Bearer %JWT_TOKEN%" ^
        -F "file=@test-file.txt" > upload_response.txt
    
    if "%HAS_JQ%"=="true" (
        for /f "delims=" %%i in ('jq -r .id upload_response.txt 2^>nul') do set FILE_ID=%%i
    )
    
    echo [INFO] Testing: Upload file - Empty file
    echo. > empty.txt
    curl -s -w "%%{http_code}" -X POST "%BASE_URL%/files/upload" ^
        -H "Authorization: Bearer %JWT_TOKEN%" ^
        -F "file=@empty.txt" > temp_response.txt
    set /p response=<temp_response.txt
    echo Response: !response!
    del empty.txt
    set /a TOTAL_TESTS+=1
    
    echo [INFO] Testing: Upload file - No auth token
    curl -s -w "%%{http_code}" -X POST "%BASE_URL%/files/upload" ^
        -F "file=@test-file.txt" > temp_response.txt
    set /p response=<temp_response.txt
    echo Response: !response!
    set /a TOTAL_TESTS+=1
    
    echo [INFO] Testing: Get user files - Default pagination
    curl -s -w "%%{http_code}" -H "Authorization: Bearer %JWT_TOKEN%" "%BASE_URL%/files" > temp_response.txt
    set /p response=<temp_response.txt
    echo Response: !response!
    set /a TOTAL_TESTS+=1
    
    echo [INFO] Testing: Get user files - With search
    curl -s -w "%%{http_code}" -H "Authorization: Bearer %JWT_TOKEN%" "%BASE_URL%/files?search=test" > temp_response.txt
    set /p response=<temp_response.txt
    echo Response: !response!
    set /a TOTAL_TESTS+=1
    
    echo [INFO] Testing: Get user files - No auth token
    curl -s -w "%%{http_code}" "%BASE_URL%/files" > temp_response.txt
    set /p response=<temp_response.txt
    echo Response: !response!
    set /a TOTAL_TESTS+=1
    
    if not "%FILE_ID%"=="" if not "%FILE_ID%"=="null" (
        echo [INFO] Testing: Download file - Valid file ID
        curl -s -w "%%{http_code}" -H "Authorization: Bearer %JWT_TOKEN%" "%BASE_URL%/files/%FILE_ID%/download" > temp_response.txt
        set /p response=<temp_response.txt
        echo Response: !response!
        set /a TOTAL_TESTS+=1
        
        echo [INFO] Testing: Create share link - Valid file
        curl -s -X POST "%BASE_URL%/files/%FILE_ID%/share" ^
            -H "Authorization: Bearer %JWT_TOKEN%" ^
            -d "expirationHours=24" > share_response.txt
        
        if "%HAS_JQ%"=="true" (
            for /f "delims=" %%i in ('jq -r .publicLinkId share_response.txt 2^>nul') do set SHARE_LINK_ID=%%i
        )
        
        curl -s -w "%%{http_code}" -X POST "%BASE_URL%/files/%FILE_ID%/share" ^
            -H "Authorization: Bearer %JWT_TOKEN%" ^
            -d "expirationHours=24" > temp_response.txt
        set /p response=<temp_response.txt
        echo Response: !response!
        set /a TOTAL_TESTS+=1
    )
    
    echo [INFO] Testing: Download file - Invalid file ID
    curl -s -w "%%{http_code}" -H "Authorization: Bearer %JWT_TOKEN%" "%BASE_URL%/files/nonexistent-id/download" > temp_response.txt
    set /p response=<temp_response.txt
    echo Response: !response!
    set /a TOTAL_TESTS+=1
    
    echo [INFO] Testing: Create share link - Invalid file ID
    curl -s -w "%%{http_code}" -X POST "%BASE_URL%/files/nonexistent-id/share" ^
        -H "Authorization: Bearer %JWT_TOKEN%" > temp_response.txt
    set /p response=<temp_response.txt
    echo Response: !response!
    set /a TOTAL_TESTS+=1
    
    if not "%SHARE_LINK_ID%"=="" if not "%SHARE_LINK_ID%"=="null" (
        echo [INFO] Testing: Download shared file - Valid link
        curl -s -w "%%{http_code}" "%BASE_URL%/files/share/%SHARE_LINK_ID%" > temp_response.txt
        set /p response=<temp_response.txt
        echo Response: !response!
        set /a TOTAL_TESTS+=1
    )
    
    echo [INFO] Testing: Download shared file - Invalid link
    curl -s -w "%%{http_code}" "%BASE_URL%/files/share/nonexistent-link" > temp_response.txt
    set /p response=<temp_response.txt
    echo Response: !response!
    set /a TOTAL_TESTS+=1
    
    echo [INFO] Testing: Get user stats - Valid token
    curl -s -w "%%{http_code}" -H "Authorization: Bearer %JWT_TOKEN%" "%BASE_URL%/files/stats" > temp_response.txt
    set /p response=<temp_response.txt
    echo Response: !response!
    set /a TOTAL_TESTS+=1
    
    echo [INFO] Testing: Get user stats - No auth token
    curl -s -w "%%{http_code}" "%BASE_URL%/files/stats" > temp_response.txt
    set /p response=<temp_response.txt
    echo Response: !response!
    set /a TOTAL_TESTS+=1
    
    if not "%FILE_ID%"=="" if not "%FILE_ID%"=="null" (
        echo [INFO] Testing: Delete file - Valid file ID
        curl -s -w "%%{http_code}" -X DELETE -H "Authorization: Bearer %JWT_TOKEN%" "%BASE_URL%/files/%FILE_ID%" > temp_response.txt
        set /p response=<temp_response.txt
        echo Response: !response!
        set /a TOTAL_TESTS+=1
    )
    
    echo [INFO] Testing: Delete file - Invalid file ID
    curl -s -w "%%{http_code}" -X DELETE -H "Authorization: Bearer %JWT_TOKEN%" "%BASE_URL%/files/nonexistent-id" > temp_response.txt
    set /p response=<temp_response.txt
    echo Response: !response!
    set /a TOTAL_TESTS+=1

) else (
    echo [WARN] Skipping file endpoint tests - JWT token not available
)

echo.
echo === EDGE CASE AND SECURITY TESTS ===

echo [INFO] Testing: CORS - Preflight request
curl -s -w "%%{http_code}" -X OPTIONS "%BASE_URL%/auth/signin" ^
    -H "Origin: http://localhost:3000" ^
    -H "Access-Control-Request-Method: POST" ^
    -H "Access-Control-Request-Headers: Content-Type" > temp_response.txt
set /p response=<temp_response.txt
echo Response: !response!
set /a TOTAL_TESTS+=1

echo [INFO] Testing: Invalid Content-Type - XML
curl -s -w "%%{http_code}" -X POST "%BASE_URL%/auth/signin" ^
    -H "Content-Type: application/xml" ^
    -d "<login><username>test</username></login>" > temp_response.txt
set /p response=<temp_response.txt
echo Response: !response!
set /a TOTAL_TESTS+=1

echo [INFO] Testing: SQL Injection attempt in username
curl -s -w "%%{http_code}" -X POST "%BASE_URL%/auth/signin" ^
    -H "Content-Type: application/json" ^
    -d "{\"username\":\"admin'; DROP TABLE users; --\",\"password\":\"password\"}" > temp_response.txt
set /p response=<temp_response.txt
echo Response: !response!
set /a TOTAL_TESTS+=1

REM Cleanup
del test-file.txt test-binary.bin temp_response.txt signin_response.txt upload_response.txt share_response.txt 2>nul

echo.
echo ==========================================
echo TEST SUMMARY
echo ==========================================
echo Total Tests: %TOTAL_TESTS%
echo.
echo [INFO] Manual verification required for pass/fail status
echo [INFO] Review the HTTP status codes above to determine test results
echo.
echo Expected status codes:
echo - Health endpoints: 200 (GET), 405 (POST)
echo - Signup valid: 200, duplicate: 409, invalid: 400
echo - Signin valid: 200, invalid: 401
echo - File operations with auth: 200, without auth: 401
echo - Invalid resources: 404
echo.

pause