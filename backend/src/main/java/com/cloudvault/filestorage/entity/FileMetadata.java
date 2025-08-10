package com.cloudvault.filestorage.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "file_metadata")
public class FileMetadata {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @NotBlank
    private String filename;

    @NotBlank
    @Column(name = "original_filename")
    private String originalFilename;

    @NotNull
    @Column(name = "file_size")
    private Long fileSize;

    @NotBlank
    @Column(name = "content_type")
    private String contentType;

    @NotBlank
    @Column(name = "file_path")
    private String filePath;

    @Column(name = "public_link_id", unique = true)
    private String publicLinkId;

    @Column(name = "public_link_expires_at")
    private LocalDateTime publicLinkExpiresAt;

    @Column(name = "is_public")
    private Boolean isPublic = false;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public FileMetadata() {}

    public FileMetadata(User user, String filename, String originalFilename, 
                       Long fileSize, String contentType, String filePath) {
        this.user = user;
        this.filename = filename;
        this.originalFilename = originalFilename;
        this.fileSize = fileSize;
        this.contentType = contentType;
        this.filePath = filePath;
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public String getFilename() {
        return filename;
    }

    public void setFilename(String filename) {
        this.filename = filename;
    }

    public String getOriginalFilename() {
        return originalFilename;
    }

    public void setOriginalFilename(String originalFilename) {
        this.originalFilename = originalFilename;
    }

    public Long getFileSize() {
        return fileSize;
    }

    public void setFileSize(Long fileSize) {
        this.fileSize = fileSize;
    }

    public String getContentType() {
        return contentType;
    }

    public void setContentType(String contentType) {
        this.contentType = contentType;
    }

    public String getFilePath() {
        return filePath;
    }

    public void setFilePath(String filePath) {
        this.filePath = filePath;
    }

    public String getPublicLinkId() {
        return publicLinkId;
    }

    public void setPublicLinkId(String publicLinkId) {
        this.publicLinkId = publicLinkId;
    }

    public LocalDateTime getPublicLinkExpiresAt() {
        return publicLinkExpiresAt;
    }

    public void setPublicLinkExpiresAt(LocalDateTime publicLinkExpiresAt) {
        this.publicLinkExpiresAt = publicLinkExpiresAt;
    }

    public Boolean getIsPublic() {
        return isPublic;
    }

    public void setIsPublic(Boolean isPublic) {
        this.isPublic = isPublic;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}