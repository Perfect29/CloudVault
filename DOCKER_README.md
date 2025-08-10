# CloudVault Docker Setup Guide

This guide provides comprehensive instructions for setting up and running CloudVault using Docker and Docker Compose for local development and production deployment.

## 📋 Prerequisites

Before you begin, ensure you have the following installed on your system:

- **Docker** (version 20.10 or higher)
- **Docker Compose** (version 2.0 or higher)
- **Git** (for cloning the repository)

### Installation Links
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows/Mac)
- [Docker Engine](https://docs.docker.com/engine/install/) (Linux)

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone <repository-url>
cd cloudvault
```

### 2. Environment Setup
```bash
# Copy the example environment file
cp .env.example .env

# Edit the .env file with your preferred settings (optional)
nano .env
```

### 3. Start Development Environment
```bash
# Using the convenience script (Linux/Mac)
./scripts/docker-dev.sh start

# Or using Docker Compose directly
docker-compose -f docker-compose.dev.yml up -d
```

### 4. Access the Application
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080/api
- **API Documentation**: http://localhost:8080/api/swagger-ui.html
- **Database**: localhost:5432 (postgres/password)

## 📁 Docker Configuration Files

### Main Configuration Files
- `docker-compose.yml` - Production configuration
- `docker-compose.dev.yml` - Development configuration with hot reload
- `Dockerfile.frontend` - Multi-stage React frontend build
- `backend/Dockerfile` - Production Spring Boot build
- `backend/Dockerfile.dev` - Development Spring Boot with hot reload

### Supporting Files
- `.env.example` - Environment variables template
- `nginx/nginx.conf` - Reverse proxy configuration
- `backend/init-db.sql` - Database initialization script
- `scripts/docker-dev.sh` - Development helper script

## 🛠️ Development Environment

The development environment includes:
- **Hot reload** for both frontend and backend
- **Database persistence** across container restarts
- **Volume mounting** for real-time code changes
- **Debug ports** exposed for IDE integration
- **Admin tools** (optional) for database and cache management

### Services Included

| Service | Port | Description |
|---------|------|-------------|
| Frontend | 3000 | React development server with HMR |
| Backend | 8080 | Spring Boot with DevTools |
| PostgreSQL | 5432 | Database server |
| Redis | 6379 | Cache server |
| pgAdmin | 5050 | Database admin (with tools profile) |
| RedisInsight | 8001 | Redis admin (with tools profile) |

### Development Commands

```bash
# Start development environment
./scripts/docker-dev.sh start

# Start with admin tools
./scripts/docker-dev.sh start-tools

# View logs
./scripts/docker-dev.sh logs
./scripts/docker-dev.sh logs backend  # Specific service

# Stop environment
./scripts/docker-dev.sh stop

# Restart environment
./scripts/docker-dev.sh restart

# Show service status
./scripts/docker-dev.sh status

# Execute commands in containers
./scripts/docker-dev.sh exec backend bash
./scripts/docker-dev.sh exec postgres psql -U postgres -d cloudvault

# Database operations
./scripts/docker-dev.sh db-info
./scripts/docker-dev.sh backup
./scripts/docker-dev.sh restore backup_file.sql

# Clean up everything
./scripts/docker-dev.sh clean
```

### Windows Users
Use the batch file equivalent:
```cmd
scripts\docker-dev.bat start
scripts\docker-dev.bat logs
scripts\docker-dev.bat stop
```

## 🏭 Production Environment

The production environment includes:
- **Optimized builds** with multi-stage Dockerfiles
- **Nginx reverse proxy** with SSL termination
- **Health checks** for all services
- **Resource limits** and restart policies
- **Security hardening** with non-root users

### Production Deployment

```bash
# Build and start production environment
docker-compose up -d

# With nginx reverse proxy
docker-compose --profile production up -d

# Scale services (if needed)
docker-compose up -d --scale backend=3
```

### Production Configuration

Key production features:
- **SSL/TLS termination** at nginx level
- **Rate limiting** for API endpoints
- **Gzip compression** for static assets
- **Security headers** for enhanced protection
- **Log aggregation** and monitoring ready

## 🗄️ Database Management

### Initial Setup
The database is automatically initialized with:
- **Schema creation** from `backend/init-db.sql`
- **Indexes** for optimal performance
- **Triggers** for data consistency
- **Default admin user** (admin@cloudvault.com / admin123)

### Database Operations

```bash
# Connect to database
docker-compose exec postgres psql -U postgres -d cloudvault

# Create backup
docker-compose exec postgres pg_dump -U postgres cloudvault > backup.sql

# Restore from backup
docker-compose exec -T postgres psql -U postgres -d cloudvault < backup.sql

# View database logs
docker-compose logs postgres
```

### Database Schema
The application uses the following main tables:
- `users` - User accounts and authentication
- `file_metadata` - File information and metadata
- `file_shares` - File sharing and permissions
- `audit_logs` - Activity tracking and auditing

## 🔧 Configuration

### Environment Variables

Key configuration options in `.env`:

```bash
# Database
DATABASE_URL=jdbc:postgresql://postgres:5432/cloudvault
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=password

# JWT Security
JWT_SECRET=your-secret-key-here

# File Storage
STORAGE_TYPE=local  # or 's3'
LOCAL_STORAGE_PATH=./uploads

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
```

### Volume Mounts

Persistent data is stored in Docker volumes:
- `postgres_data` - Database files
- `redis_data` - Cache data
- `file_uploads` - Uploaded files
- `maven_cache` - Maven dependencies (dev)
- `node_modules` - Node.js dependencies (dev)

## 🔍 Monitoring and Debugging

### Health Checks
All services include health checks:
```bash
# Check service health
docker-compose ps

# View health check logs
docker inspect <container_name> | grep -A 10 Health
```

### Log Management
```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend
docker-compose logs -f postgres

# Follow logs with timestamps
docker-compose logs -f -t
```

### Debug Ports
Development containers expose debug ports:
- **Backend**: 5005 (Java debug)
- **Frontend**: 24678 (Vite HMR)

Connect your IDE to these ports for debugging.

## 🚨 Troubleshooting

### Common Issues

#### Port Conflicts
```bash
# Check what's using a port
lsof -i :8080
netstat -tulpn | grep :8080

# Stop conflicting services
sudo systemctl stop postgresql  # If local PostgreSQL is running
```

#### Permission Issues
```bash
# Fix file permissions
sudo chown -R $USER:$USER .
chmod +x scripts/docker-dev.sh
```

#### Database Connection Issues
```bash
# Reset database
docker-compose down -v
docker-compose up -d postgres
# Wait for database to be ready, then start other services
```

#### Out of Disk Space
```bash
# Clean up Docker resources
docker system prune -a
docker volume prune
```

### Performance Optimization

#### For Development
- Increase Docker Desktop memory allocation (8GB recommended)
- Use volume mounts instead of bind mounts for better performance on Windows/Mac
- Enable BuildKit for faster builds: `export DOCKER_BUILDKIT=1`

#### For Production
- Use multi-stage builds to reduce image size
- Implement proper resource limits
- Use external databases for better performance
- Enable log rotation

## 🔐 Security Considerations

### Development Security
- Default passwords are used for convenience
- CORS is permissive for local development
- Debug ports are exposed

### Production Security
- Change all default passwords
- Use environment-specific secrets
- Implement proper CORS policies
- Close debug ports
- Use HTTPS with proper certificates
- Implement rate limiting
- Regular security updates

## 📚 Additional Resources

### Docker Documentation
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Security](https://docs.docker.com/engine/security/)

### Application Documentation
- [Spring Boot Docker Guide](https://spring.io/guides/gs/spring-boot-docker/)
- [React Docker Deployment](https://create-react-app.dev/docs/deployment/#docker)
- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)

## 🤝 Contributing

When contributing to the Docker configuration:

1. Test changes in both development and production modes
2. Update documentation for any new environment variables
3. Ensure backward compatibility
4. Add health checks for new services
5. Update the helper scripts as needed

## 📞 Support

If you encounter issues with the Docker setup:

1. Check the troubleshooting section above
2. Review Docker and Docker Compose logs
3. Ensure your Docker version meets requirements
4. Check for port conflicts and permission issues
5. Create an issue with detailed error messages and system information

---

**Happy Coding! 🚀**