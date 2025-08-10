# CloudVault File Storage Backend

A robust Spring Boot REST API for secure file storage and sharing with JWT authentication, featuring comprehensive error handling, service layer architecture, and extensive testing.

## Features

- **User Authentication**: JWT-based registration and login with secure password hashing
- **File Upload**: Secure file upload with validation, metadata storage, and type restrictions
- **File Download**: Download files with proper authorization and content headers
- **Public Sharing**: Generate shareable links with optional expiration (up to 1 year)
- **File Management**: List, search, and delete user files with pagination
- **Storage Stats**: Track user storage usage and file counts
- **Global Exception Handling**: Comprehensive error handling with proper HTTP status codes
- **Service Layer Architecture**: Clean separation of concerns with interfaces and implementations
- **Comprehensive Testing**: Unit and integration tests for all components

## Tech Stack

- **Java 17+**
- **Spring Boot 3.x**
- **Spring Security** (JWT Authentication)
- **Spring Data JPA** (PostgreSQL)
- **Maven** (Build tool)
- **Docker** (Containerization)
- **JUnit 5** (Testing)
- **Mockito** (Mocking framework)

## Architecture

### Layer Structure
```
├── Controller Layer (REST endpoints)
├── Service Layer (Business logic)
├── Repository Layer (Data access)
├── Entity Layer (JPA entities)
├── DTO Layer (Data transfer objects)
├── Security Layer (JWT & authentication)
└── Exception Layer (Global error handling)
```

### Key Components
- **FileService**: File operations business logic
- **UserService**: User management business logic
- **FileStorageService**: Physical file storage operations
- **GlobalExceptionHandler**: Centralized error handling
- **Custom Exceptions**: Domain-specific exceptions

## Quick Start

### Prerequisites

- Java 17 or higher
- PostgreSQL 12+
- Maven 3.6+ (or use included wrapper)

### Local Development

1. **Clone and navigate to backend**:
   ```bash
   cd backend
   ```

2. **Set up PostgreSQL database**:
   ```sql
   CREATE DATABASE cloudvault;
   CREATE USER cloudvault_user WITH PASSWORD 'your_password';
   GRANT ALL PRIVILEGES ON DATABASE cloudvault TO cloudvault_user;
   ```

3. **Configure environment variables**:
   ```bash
   export DATABASE_URL=jdbc:postgresql://localhost:5432/cloudvault
   export DATABASE_USERNAME=cloudvault_user
   export DATABASE_PASSWORD=your_password
   export JWT_SECRET=your-very-secure-256-bit-secret-key-change-in-production
   export LOCAL_STORAGE_PATH=./uploads
   export CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
   ```

4. **Run the application**:
   ```bash
   ./mvnw spring-boot:run
   ```

The API will be available at `http://localhost:8080/api`

### Docker Development

1. **Start with Docker Compose**:
   ```bash
   docker-compose up -d
   ```

This starts both PostgreSQL and the Spring Boot application with proper networking.

## API Endpoints

### Authentication

- `POST /api/auth/signup` - Register new user
  ```json
  {
    "username": "johndoe",
    "email": "john@example.com", 
    "password": "securepassword"
  }
  ```

- `POST /api/auth/signin` - Login user
  ```json
  {
    "username": "johndoe",
    "password": "securepassword"
  }
  ```

- `GET /api/auth/me` - Get current user info (requires JWT)

### File Operations

- `POST /api/files/upload` - Upload file (multipart/form-data, requires JWT)
- `GET /api/files` - List user files with pagination and search (requires JWT)
  - Query params: `page`, `size`, `search`
- `GET /api/files/{fileId}/download` - Download file (requires JWT)
- `DELETE /api/files/{fileId}` - Delete file (requires JWT)
- `GET /api/files/stats` - Get user storage statistics (requires JWT)

### Public Sharing

- `POST /api/files/{fileId}/share` - Create public share link (requires JWT)
  - Query param: `expirationHours` (optional, max 8760)
- `GET /api/files/share/{publicLinkId}` - Download shared file (public access)

### Health Check

- `GET /api/health` - Application health status

## Security Features

- **JWT Authentication**: Stateless authentication using JSON Web Tokens
- **Password Encryption**: BCrypt password hashing with salt
- **File Access Control**: Users can only access their own files
- **Path Traversal Protection**: Prevents directory traversal attacks
- **File Type Validation**: Restricts to safe file extensions
- **Size Limits**: Configurable file size limits (default: 100MB)
- **Input Validation**: Comprehensive validation using Bean Validation
- **CORS Configuration**: Configurable cross-origin resource sharing

## File Type Support

Allowed file extensions:
- **Images**: .jpg, .jpeg, .png, .gif
- **Documents**: .pdf, .doc, .docx, .xls, .xlsx, .ppt, .pptx, .txt
- **Archives**: .zip, .rar

## Configuration

Key configuration properties in `application.yml`:

```yaml
# Database with connection pooling
spring:
  datasource:
    url: ${DATABASE_URL}
    username: ${DATABASE_USERNAME}
    password: ${DATABASE_PASSWORD}
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5

# JWT Security
app:
  jwt:
    secret: ${JWT_SECRET} # Must be 256-bit minimum
    expiration: 86400000 # 24 hours

# File Storage
file:
  storage:
    type: local # or s3
    local:
      path: ${LOCAL_STORAGE_PATH:./uploads}

# CORS
cors:
  allowed-origins: ${CORS_ALLOWED_ORIGINS}

# File Upload Limits
spring:
  servlet:
    multipart:
      max-file-size: 100MB
      max-request-size: 100MB
```

## Database Schema

### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(120) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### File Metadata Table
```sql
CREATE TABLE file_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    file_size BIGINT NOT NULL,
    content_type VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    public_link_id VARCHAR(255) UNIQUE,
    public_link_expires_at TIMESTAMP,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Testing

### Run Tests
```bash
./mvnw test
```

### Test Coverage
- **Unit Tests**: Service layer business logic
- **Integration Tests**: Controller endpoints with mocked dependencies
- **Security Tests**: Authentication and authorization scenarios

### Test Structure
```
src/test/java/
├── service/
│   ├── FileServiceImplTest.java
│   └── UserServiceImplTest.java
└── controller/
    ├── FileControllerTest.java
    └── AuthControllerTest.java
```

## Error Handling

### Global Exception Handler
The application includes comprehensive error handling:

- **FileNotFoundException**: 404 - File not found
- **FileStorageException**: 500 - File storage errors
- **UserNotFoundException**: 404 - User not found
- **BadCredentialsException**: 401 - Authentication failed
- **AccessDeniedException**: 403 - Access denied
- **ValidationException**: 400 - Input validation errors
- **MaxUploadSizeExceededException**: 413 - File too large

### Error Response Format
```json
{
  "timestamp": "2024-01-20T10:30:00",
  "status": 404,
  "error": "File not found",
  "message": "File not found with ID: abc123"
}
```

## Production Deployment

### Environment Variables

**Required for Production:**
```bash
# Database
DATABASE_URL=jdbc:postgresql://your-db-host:5432/cloudvault
DATABASE_USERNAME=your-db-user
DATABASE_PASSWORD=your-secure-password

# JWT (CRITICAL: Use a strong 256-bit secret)
JWT_SECRET=your-very-secure-256-bit-secret-key-for-production

# Storage
LOCAL_STORAGE_PATH=/app/uploads
# OR for S3:
STORAGE_TYPE=s3
S3_BUCKET_NAME=your-s3-bucket
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# CORS
CORS_ALLOWED_ORIGINS=https://your-frontend-domain.com

# Server
PORT=8080
SPRING_PROFILES_ACTIVE=prod
```

### Docker Production

1. **Build the image**:
   ```bash
   docker build -t cloudvault-backend .
   ```

2. **Run with environment variables**:
   ```bash
   docker run -d \
     -p 8080:8080 \
     -e DATABASE_URL=your-db-url \
     -e JWT_SECRET=your-secret \
     -e CORS_ALLOWED_ORIGINS=https://yourdomain.com \
     cloudvault-backend
   ```

### Health Monitoring

The application exposes health endpoints:
- `/api/health` - Basic health check
- `/actuator/health` - Detailed health information
- `/actuator/metrics` - Application metrics

## Development Guidelines

### Code Structure
- **Controllers**: Handle HTTP requests/responses only
- **Services**: Contain business logic and validation
- **Repositories**: Handle data persistence
- **DTOs**: Transfer data between layers
- **Entities**: JPA database entities

### Best Practices
- Use service interfaces for loose coupling
- Implement comprehensive error handling
- Write unit tests for all business logic
- Use transactions for data consistency
- Validate all inputs at multiple layers
- Follow REST API conventions

## Troubleshooting

### Common Issues

1. **Database Connection Errors**:
   - Verify PostgreSQL is running
   - Check connection URL and credentials
   - Ensure database exists

2. **File Upload Failures**:
   - Check file size limits in configuration
   - Verify storage directory permissions
   - Ensure allowed file types

3. **JWT Authentication Issues**:
   - Verify JWT secret is at least 256 bits
   - Check token expiration settings
   - Validate CORS configuration

4. **CORS Problems**:
   - Update allowed origins in application.yml
   - Verify frontend URL matches configuration

### Debug Mode

Enable debug logging:
```yaml
logging:
  level:
    com.cloudvault: DEBUG
    org.springframework.security: DEBUG
```

### Performance Tuning

For high-load scenarios:
- Increase database connection pool size
- Configure JVM heap settings
- Enable database query optimization
- Consider implementing caching

## API Usage Examples

### Upload File
```bash
curl -X POST \
  -H "Authorization: Bearer your-jwt-token" \
  -F "file=@/path/to/your/file.pdf" \
  http://localhost:8080/api/files/upload
```

### List Files
```bash
curl -X GET \
  -H "Authorization: Bearer your-jwt-token" \
  "http://localhost:8080/api/files?page=0&size=10&search=document"
```

### Create Share Link
```bash
curl -X POST \
  -H "Authorization: Bearer your-jwt-token" \
  "http://localhost:8080/api/files/file-id/share?expirationHours=24"
```

## Contributing

1. Follow the existing code structure and patterns
2. Write tests for new functionality
3. Update documentation for API changes
4. Ensure all tests pass before submitting
5. Follow Java coding conventions