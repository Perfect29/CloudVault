# CloudVault - Enterprise File Storage Platform

A full-stack file storage web application built with Spring Boot and React, demonstrating modern enterprise development practices.

## 🚀 Features

- **Secure Authentication** - JWT-based user authentication with Spring Security
- **File Management** - Upload, download, and organize files with metadata tracking
- **Public Sharing** - Generate secure shareable links with optional expiration
- **Storage Flexibility** - Configurable storage backends (Local filesystem or AWS S3)
- **Responsive Design** - Modern React UI with Tailwind CSS
- **Docker Ready** - Fully containerized with Docker Compose
- **Database Integration** - PostgreSQL with JPA/Hibernate ORM
- **RESTful API** - Well-documented REST endpoints
- **Comprehensive Testing** - Unit and integration tests

## 🛠 Technology Stack

### Backend
- **Java 17** with **Spring Boot 3.2**
- **Spring Security** for authentication and authorization
- **PostgreSQL** database with **JPA/Hibernate**
- **JWT** for stateless authentication
- **AWS S3 SDK** for cloud storage
- **Maven** for dependency management
- **JUnit 5** and **Testcontainers** for testing

### Frontend
- **React 19** with **TypeScript**
- **Vite** for fast development and building
- **Tailwind CSS** for styling
- **Radix UI** and **ShadCN/UI** for components
- **React Router** for navigation
- **React Hook Form** with **Zod** validation

### DevOps
- **Docker** and **Docker Compose**
- **Nginx** reverse proxy
- **Multi-stage builds** for optimization
- **Environment-based configuration**

## 📋 Prerequisites

- **Docker** and **Docker Compose**
- **Java 17** (for local development)
- **Node.js 18+** (for local development)
- **PostgreSQL** (if running without Docker)

## 🚀 Quick Start

### Using Docker (Recommended)

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd cloudvault-file-storage
   ```

2. **One-command start** 
   
   **Linux/Mac:**
   ```bash
   ./start-local.sh
   ```
   
   **Windows:**
   ```cmd
   start-local.bat
   ```
   
   **Or manually:**
   ```bash
   docker-compose up --build
   ```

3. **Access the application**
   - **Frontend**: http://localhost:3000
   - **Backend API**: http://localhost:8080/api
   - **Database**: localhost:5432

   ⏱️ **The application will be ready in 2-3 minutes after all containers start!**

### Local Development

1. **Start PostgreSQL**
   ```bash
   docker run -d --name postgres \
     -e POSTGRES_DB=cloudvault \
     -e POSTGRES_USER=postgres \
     -e POSTGRES_PASSWORD=password \
     -p 5432:5432 postgres:15
   ```

2. **Run Backend**
   ```bash
   cd backend
   ./mvnw spring-boot:run
   ```

3. **Run Frontend**
   ```bash
   npm install
   npm run dev
   ```

## 🔧 Configuration

### Environment Variables

#### Backend Configuration
```bash
# Database
DATABASE_URL=jdbc:postgresql://localhost:5432/cloudvault
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=password

# JWT
JWT_SECRET=your-secret-key-here

# Storage (choose one)
STORAGE_TYPE=local  # or 's3'
LOCAL_STORAGE_PATH=./uploads

# AWS S3 (if using S3)
S3_BUCKET_NAME=your-bucket-name
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000
```

#### Frontend Configuration
```bash
VITE_API_BASE_URL=http://localhost:8080/api
```

## 📚 API Documentation

### Authentication Endpoints
```
POST /api/auth/signup    - User registration
POST /api/auth/signin    - User login
GET  /api/auth/me        - Get current user
```

### File Management Endpoints
```
POST   /api/files/upload     - Upload files
GET    /api/files            - List user files
GET    /api/files/{id}       - Get file details
DELETE /api/files/{id}       - Delete file
GET    /api/files/{id}/download - Download file
```

### File Sharing Endpoints
```
POST /api/files/{id}/share   - Create public share link
GET  /api/share/{token}      - Access shared file
```

## 🧪 Testing

### Backend Tests
```bash
cd backend

# Run unit tests
./mvnw test

# Run integration tests
./mvnw verify

# Run all tests with coverage
./mvnw clean verify jacoco:report
```

### Frontend Tests
```bash
# Run tests
npm test

# Run tests with coverage
npm run test:coverage
```

## 🐳 Docker Commands

### Development Environment
```bash
# Start development environment
docker-compose -f docker-compose.dev.yml up

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Production Deployment
```bash
# Build and start production environment
docker-compose up -d

# Scale services
docker-compose up -d --scale backend=3

# Update services
docker-compose pull && docker-compose up -d
```

## 📁 Project Structure

```
cloudvault-file-storage/
├── backend/                 # Spring Boot application
│   ├── src/main/java/      # Java source code
│   ├── src/test/java/      # Test files
│   ├── src/main/resources/ # Configuration files
│   └── pom.xml             # Maven dependencies
├── src/                    # React frontend
│   ├── components/         # React components
│   ├── pages/             # Page components
│   ├── hooks/             # Custom hooks
│   └── lib/               # Utilities
├── nginx/                 # Nginx configuration
├── scripts/               # Utility scripts
├── docker-compose.yml     # Production compose file
├── docker-compose.dev.yml # Development compose file
└── README.md
```

## 🔒 Security Features

- **JWT Authentication** - Stateless token-based authentication
- **Password Encryption** - BCrypt hashing for user passwords
- **CORS Protection** - Configurable cross-origin request handling
- **Input Validation** - Request data validation and sanitization
- **File Access Control** - User-specific file access permissions
- **SQL Injection Prevention** - Parameterized queries with JPA

## 🚀 Performance Optimizations

- **Connection Pooling** - HikariCP for database connections
- **JPA Batch Processing** - Optimized database operations
- **Frontend Code Splitting** - Lazy loading with React and Vite
- **Docker Multi-stage Builds** - Optimized container images
- **Nginx Caching** - Static asset caching and compression

## 📊 Monitoring

The application includes health check endpoints:
- `GET /api/actuator/health` - Application health status
- `GET /api/actuator/info` - Application information
- `GET /api/actuator/metrics` - Application metrics

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Spring Boot team for the excellent framework
- React team for the powerful UI library
- PostgreSQL community for the robust database
- Docker team for containerization technology

---

**Note**: This is a demonstration project showcasing full-stack development skills with modern technologies and best practices.