-- CloudVault Database Initialization Script
-- This script sets up the initial database schema and indexes

-- Create database if it doesn't exist (handled by Docker environment)
-- CREATE DATABASE IF NOT EXISTS cloudvault;

-- Use the database
\c cloudvault;

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    storage_quota BIGINT DEFAULT 5368709120, -- 5GB in bytes
    storage_used BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE
);

-- Create file_metadata table
CREATE TABLE IF NOT EXISTS file_metadata (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    file_size BIGINT NOT NULL,
    content_type VARCHAR(100) NOT NULL,
    file_path TEXT NOT NULL,
    file_hash VARCHAR(64), -- SHA-256 hash for deduplication
    public_link_id UUID UNIQUE,
    public_link_expires_at TIMESTAMP WITH TIME ZONE,
    is_public BOOLEAN DEFAULT FALSE,
    download_count INTEGER DEFAULT 0,
    tags TEXT[], -- Array of tags
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete
);

-- Create file_shares table for tracking shared files
CREATE TABLE IF NOT EXISTS file_shares (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_id UUID NOT NULL REFERENCES file_metadata(id) ON DELETE CASCADE,
    shared_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    shared_with_email VARCHAR(100),
    share_token VARCHAR(255) UNIQUE NOT NULL,
    permissions VARCHAR(20) DEFAULT 'read', -- read, write, admin
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    access_count INTEGER DEFAULT 0,
    last_accessed TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create audit_logs table for tracking file operations
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    file_id UUID REFERENCES file_metadata(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL, -- upload, download, delete, share, etc.
    ip_address INET,
    user_agent TEXT,
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

CREATE INDEX IF NOT EXISTS idx_file_metadata_user_id ON file_metadata(user_id);
CREATE INDEX IF NOT EXISTS idx_file_metadata_filename ON file_metadata(filename);
CREATE INDEX IF NOT EXISTS idx_file_metadata_content_type ON file_metadata(content_type);
CREATE INDEX IF NOT EXISTS idx_file_metadata_created_at ON file_metadata(created_at);
CREATE INDEX IF NOT EXISTS idx_file_metadata_public_link_id ON file_metadata(public_link_id);
CREATE INDEX IF NOT EXISTS idx_file_metadata_is_public ON file_metadata(is_public);
CREATE INDEX IF NOT EXISTS idx_file_metadata_deleted_at ON file_metadata(deleted_at);
CREATE INDEX IF NOT EXISTS idx_file_metadata_file_hash ON file_metadata(file_hash);

-- GIN index for full-text search on filename
CREATE INDEX IF NOT EXISTS idx_file_metadata_filename_gin ON file_metadata USING GIN (filename gin_trgm_ops);

-- Index for tags array
CREATE INDEX IF NOT EXISTS idx_file_metadata_tags ON file_metadata USING GIN (tags);

CREATE INDEX IF NOT EXISTS idx_file_shares_file_id ON file_shares(file_id);
CREATE INDEX IF NOT EXISTS idx_file_shares_shared_by ON file_shares(shared_by);
CREATE INDEX IF NOT EXISTS idx_file_shares_share_token ON file_shares(share_token);
CREATE INDEX IF NOT EXISTS idx_file_shares_expires_at ON file_shares(expires_at);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_file_id ON audit_logs(file_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_file_metadata_updated_at BEFORE UPDATE ON file_metadata
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to update user storage usage
CREATE OR REPLACE FUNCTION update_user_storage_usage()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE users 
        SET storage_used = storage_used + NEW.file_size 
        WHERE id = NEW.user_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE users 
        SET storage_used = storage_used - OLD.file_size 
        WHERE id = OLD.user_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

-- Create triggers for storage usage tracking
CREATE TRIGGER update_storage_on_insert AFTER INSERT ON file_metadata
    FOR EACH ROW EXECUTE FUNCTION update_user_storage_usage();

CREATE TRIGGER update_storage_on_delete AFTER DELETE ON file_metadata
    FOR EACH ROW EXECUTE FUNCTION update_user_storage_usage();

-- Insert default admin user (password: admin123)
-- Note: In production, this should be removed or changed
INSERT INTO users (username, email, password, first_name, last_name, is_verified) 
VALUES (
    'admin', 
    'admin@cloudvault.com', 
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- bcrypt hash of 'admin123'
    'Admin',
    'User',
    TRUE
) ON CONFLICT (email) DO NOTHING;

-- Create views for common queries
CREATE OR REPLACE VIEW user_file_stats AS
SELECT 
    u.id as user_id,
    u.username,
    u.email,
    COUNT(fm.id) as total_files,
    COALESCE(SUM(fm.file_size), 0) as total_size,
    COUNT(CASE WHEN fm.is_public = TRUE THEN 1 END) as public_files,
    u.storage_quota,
    u.storage_used,
    ROUND((u.storage_used::DECIMAL / u.storage_quota::DECIMAL) * 100, 2) as storage_usage_percent
FROM users u
LEFT JOIN file_metadata fm ON u.id = fm.user_id AND fm.deleted_at IS NULL
GROUP BY u.id, u.username, u.email, u.storage_quota, u.storage_used;

-- Grant permissions (adjust as needed for your security requirements)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO cloudvault_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO cloudvault_user;

-- Print completion message
DO $$
BEGIN
    RAISE NOTICE 'CloudVault database initialization completed successfully!';
    RAISE NOTICE 'Tables created: users, file_metadata, file_shares, audit_logs';
    RAISE NOTICE 'Indexes and triggers created for optimal performance';
    RAISE NOTICE 'Default admin user created with email: admin@cloudvault.com';
END $$;