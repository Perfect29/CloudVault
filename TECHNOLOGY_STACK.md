# CloudVault - Technology Stack Documentation

## Project Overview
CloudVault is a full-stack file storage platform demonstrating modern web development practices with enterprise-grade architecture. The application provides secure file upload, storage, sharing, and management capabilities.

## Architecture
- **Pattern**: Microservices architecture with containerized deployment
- **Communication**: RESTful API with JSON data exchange
- **Authentication**: JWT-based stateless authentication
- **Storage**: Configurable backend (Local filesystem or AWS S3)
- **Database**: PostgreSQL with JPA/Hibernate ORM

## Backend Technologies

### Core Framework
- **Spring Boot 3.2.1** - Main application framework
- **Java 17** - Programming language with modern features
- **Maven 3.9+** - Dependency management and build automation

### Security & Authentication
- **Spring Security 6.x** - Comprehensive security framework
- **JWT (JSON Web Tokens)** - Stateless authentication mechanism
- **JJWT 0.11.5** - JWT implementation library
- **BCrypt** - Password hashing algorithm

### Database & Persistence
- **PostgreSQL 15+** - Primary relational database
- **Spring Data JPA** - Data access abstraction layer
- **Hibernate 6.x** - Object-relational mapping (ORM)
- **HikariCP** - High-performance connection pooling

### File Storage
- **AWS SDK for Java 2.21.29** - Amazon S3 integration
- **Local File System** - Alternative storage backend
- **Multipart File Upload** - Large file handling support

### Testing Framework
- **JUnit 5** - Unit testing framework
- **Spring Boot Test** - Integration testing support
- **Testcontainers** - Database integration testing
- **H2 Database** - In-memory testing database
- **Mockito** - Mocking framework

### Build & Quality
- **Maven Surefire Plugin** - Unit test execution
- **Maven Failsafe Plugin** - Integration test execution
- **JaCoCo** - Code coverage analysis

## Frontend Technologies

### Core Framework
- **React 19** - Modern UI library with concurrent features
- **TypeScript 5.8** - Type-safe JavaScript development
- **Vite 7.0** - Fast build tool and development server

### UI Components & Styling
- **Tailwind CSS 3.3** - Utility-first CSS framework
- **Radix UI** - Accessible component primitives
- **ShadCN/UI** - Pre-built component library
- **Lucide React** - Modern icon library
- **Framer Motion** - Animation library

### State Management & Routing
- **React Router DOM 7.7** - Client-side routing
- **React Hook Form 7.62** - Form state management
- **Zod 4.0** - Schema validation library

### Development Tools
- **ESLint 9.30** - Code linting and quality
- **TypeScript ESLint** - TypeScript-specific linting
- **PostCSS** - CSS processing
- **Autoprefixer** - CSS vendor prefixing

## DevOps & Deployment

### Containerization
- **Docker** - Application containerization
- **Docker Compose** - Multi-container orchestration
- **Multi-stage Builds** - Optimized container images

### Web Server
- **Nginx** - Reverse proxy and static file serving
- **SSL/TLS Support** - HTTPS configuration ready

### Database
- **PostgreSQL Docker Image** - Containerized database
- **Volume Persistence** - Data persistence across restarts
- **Connection Pooling** - Optimized database connections

### Development Environment
- **Hot Reload** - Frontend development server
- **Live Reload** - Backend development with Spring Boot DevTools
- **Environment Variables** - Configuration management

## API Design

### REST Endpoints
- **Authentication**: `/api/auth/signin`, `/api/auth/signup`
- **File Management**: `/api/files/upload`, `/api/files/download/{id}`
- **File Sharing**: `/api/files/{id}/share`, `/api/share/{token}`
- **User Management**: `/api/users/profile`

### HTTP Methods
- **GET** - Data retrieval operations
- **POST** - Resource creation (upload, authentication)
- **PUT** - Resource updates
- **DELETE** - Resource deletion

### Response Format
- **JSON** - Structured data exchange
- **HTTP Status Codes** - Proper status code usage
- **Error Handling** - Consistent error response format

## Security Features

### Authentication & Authorization
- **JWT Tokens** - Stateless authentication
- **Password Encryption** - BCrypt hashing
- **Role-based Access** - User permission system
- **Session Management** - Token expiration handling

### File Security
- **Access Control** - User-specific file access
- **Public Link Sharing** - Controlled file sharing
- **File Validation** - MIME type verification
- **Upload Limits** - File size restrictions

### API Security
- **CORS Configuration** - Cross-origin request handling
- **Input Validation** - Request data validation
- **SQL Injection Prevention** - Parameterized queries
- **XSS Protection** - Output encoding

## Database Schema

### Users Table
```sql
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### File Metadata Table
```sql
CREATE TABLE file_metadata (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id),
    filename TEXT NOT NULL,
    original_filename TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    content_type TEXT NOT NULL,
    file_path TEXT NOT NULL,
    public_url TEXT,
    public_link_id TEXT,
    public_link_expires_at TIMESTAMP,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Performance Optimizations

### Backend
- **Connection Pooling** - HikariCP for database connections
- **JPA Batch Processing** - Optimized database operations
- **Lazy Loading** - Efficient data fetching
- **Caching** - Application-level caching strategies

### Frontend
- **Code Splitting** - Lazy loading of components
- **Bundle Optimization** - Vite build optimizations
- **Image Optimization** - Efficient asset loading
- **Memoization** - React performance optimizations

### Database
- **Indexing** - Optimized query performance
- **Query Optimization** - Efficient SQL queries
- **Connection Management** - Pool size optimization

## Monitoring & Logging

### Application Monitoring
- **Spring Boot Actuator** - Health checks and metrics
- **Custom Health Indicators** - Application-specific monitoring
- **JVM Metrics** - Memory and performance monitoring

### Logging
- **SLF4J** - Logging facade
- **Logback** - Logging implementation
- **Structured Logging** - JSON log format
- **Log Levels** - Configurable logging levels

## Configuration Management

### Environment Variables
- **Database Configuration** - Connection parameters
- **JWT Configuration** - Secret keys and expiration
- **Storage Configuration** - S3 or local storage settings
- **CORS Configuration** - Allowed origins and methods

### Profiles
- **Development Profile** - Local development settings
- **Production Profile** - Production-ready configuration
- **Test Profile** - Testing environment settings

## Skills Demonstrated

### Backend Development
- Spring Boot application development
- RESTful API design and implementation
- Database design and optimization
- Security implementation (JWT, Spring Security)
- File upload and storage handling
- Unit and integration testing
- Docker containerization

### Frontend Development
- Modern React development with hooks
- TypeScript for type safety
- Responsive UI design with Tailwind CSS
- State management and form handling
- API integration and error handling
- Component-based architecture

### DevOps & Infrastructure
- Docker and Docker Compose
- Nginx configuration
- Database administration
- Environment configuration
- CI/CD pipeline setup (GitHub Actions ready)

### Software Engineering Practices
- Clean code principles
- SOLID design principles
- Test-driven development
- API documentation
- Version control with Git
- Agile development practices

## Deployment Instructions

### Development Environment
```bash
# Clone repository
git clone <repository-url>

# Start with Docker Compose
docker-compose -f docker-compose.dev.yml up

# Access application
Frontend: http://localhost:3000
Backend API: http://localhost:8080/api
Database: localhost:5432
```

### Production Deployment
```bash
# Build and deploy
docker-compose up -d

# Monitor logs
docker-compose logs -f
```

This technology stack demonstrates proficiency in modern full-stack development, containerization, security best practices, and enterprise-grade application architecture.