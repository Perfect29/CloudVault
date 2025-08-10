package com.cloudvault.filestorage.dto;

import com.cloudvault.filestorage.entity.FileMetadata;

import java.time.LocalDateTime;

public class FileResponse {
    private String id;
    private String filename;
    private String originalFilename;
    private Long fileSize;
    private String contentType;
    private String publicLinkId;
    private LocalDateTime publicLinkExpiresAt;
    private Boolean isPublic;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public FileResponse() {}

    public FileResponse(FileMetadata fileMetadata) {
        this.id = fileMetadata.getId();
        this.filename = fileMetadata.getFilename();
        this.originalFilename = fileMetadata.getOriginalFilename();
        this.fileSize = fileMetadata.getFileSize();
        this.contentType = fileMetadata.getContentType();
        this.publicLinkId = fileMetadata.getPublicLinkId();
        this.publicLinkExpiresAt = fileMetadata.getPublicLinkExpiresAt();
        this.isPublic = fileMetadata.getIsPublic();
        this.createdAt = fileMetadata.getCreatedAt();
        this.updatedAt = fileMetadata.getUpdatedAt();
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
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