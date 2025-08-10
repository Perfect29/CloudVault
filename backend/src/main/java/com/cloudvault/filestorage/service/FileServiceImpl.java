package com.cloudvault.filestorage.service;

import com.cloudvault.filestorage.dto.FileResponse;
import com.cloudvault.filestorage.entity.FileMetadata;
import com.cloudvault.filestorage.entity.User;
import com.cloudvault.filestorage.exception.FileNotFoundException;
import com.cloudvault.filestorage.exception.FileStorageException;
import com.cloudvault.filestorage.repository.FileMetadataRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
@Transactional
public class FileServiceImpl implements FileService {

    @Autowired
    private FileStorageService fileStorageService;

    @Autowired
    private FileMetadataRepository fileMetadataRepository;

    @Override
    public FileResponse uploadFile(MultipartFile file, User user) throws IOException {
        if (file.isEmpty()) {
            throw new FileStorageException("Cannot upload empty file");
        }

        if (file.getSize() > 100 * 1024 * 1024) { // 100MB limit
            throw new FileStorageException("File size exceeds maximum limit of 100MB");
        }

        try {
            // Store the physical file
            String fileName = fileStorageService.storeFile(file);

            // Save file metadata
            FileMetadata fileMetadata = new FileMetadata(
                    user,
                    fileName,
                    file.getOriginalFilename(),
                    file.getSize(),
                    file.getContentType(),
                    fileName
            );

            fileMetadata = fileMetadataRepository.save(fileMetadata);
            return new FileResponse(fileMetadata);

        } catch (IOException ex) {
            throw new FileStorageException("Failed to store file: " + ex.getMessage(), ex);
        }
    }

    @Override
    @Transactional(readOnly = true)
    public Page<FileMetadata> getUserFiles(User user, String search, Pageable pageable) {
        if (search != null && !search.trim().isEmpty()) {
            return fileMetadataRepository.findByUserAndFilenameContainingIgnoreCase(user, search.trim(), pageable);
        } else {
            return fileMetadataRepository.findByUserOrderByCreatedAtDesc(user, pageable);
        }
    }

    @Override
    @Transactional(readOnly = true)
    public Resource downloadFile(String fileId, User user) throws IOException {
        FileMetadata fileMetadata = getFileMetadata(fileId, user);

        try {
            return fileStorageService.loadFileAsResource(fileMetadata.getFilename());
        } catch (IOException ex) {
            throw new FileNotFoundException("File not found on storage: " + fileMetadata.getOriginalFilename(), ex);
        }
    }

    @Override
    public Map<String, Object> createShareLink(String fileId, Integer expirationHours, User user) {
        FileMetadata fileMetadata = getFileMetadata(fileId, user);

        // Generate public link ID
        String publicLinkId = UUID.randomUUID().toString();
        fileMetadata.setPublicLinkId(publicLinkId);
        fileMetadata.setIsPublic(true);

        // Set expiration if provided
        if (expirationHours != null && expirationHours > 0) {
            if (expirationHours > 8760) { // Max 1 year
                throw new IllegalArgumentException("Expiration cannot exceed 1 year (8760 hours)");
            }
            fileMetadata.setPublicLinkExpiresAt(LocalDateTime.now().plusHours(expirationHours));
        }

        fileMetadataRepository.save(fileMetadata);

        Map<String, Object> response = new HashMap<>();
        response.put("publicLinkId", publicLinkId);
        response.put("shareUrl", "/files/share/" + publicLinkId);
        response.put("expiresAt", fileMetadata.getPublicLinkExpiresAt());

        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public Resource downloadSharedFile(String publicLinkId) throws IOException {
        FileMetadata fileMetadata = getSharedFileMetadata(publicLinkId);

        try {
            return fileStorageService.loadFileAsResource(fileMetadata.getFilename());
        } catch (IOException ex) {
            throw new FileNotFoundException("Shared file not found on storage: " + fileMetadata.getOriginalFilename(), ex);
        }
    }

    @Override
    public void deleteFile(String fileId, User user) throws IOException {
        FileMetadata fileMetadata = getFileMetadata(fileId, user);

        try {
            // Delete physical file
            fileStorageService.deleteFile(fileMetadata.getFilename());
        } catch (IOException ex) {
            throw new FileStorageException("Failed to delete physical file: " + ex.getMessage(), ex);
        }

        // Delete metadata
        fileMetadataRepository.delete(fileMetadata);
    }

    @Override
    @Transactional(readOnly = true)
    public Map<String, Object> getUserStats(User user) {
        Long totalFiles = fileMetadataRepository.countByUser(user);
        Long totalSize = fileMetadataRepository.getTotalFileSizeByUser(user);

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalFiles", totalFiles != null ? totalFiles : 0);
        stats.put("totalSize", totalSize != null ? totalSize : 0);

        return stats;
    }

    @Override
    @Transactional(readOnly = true)
    public FileMetadata getFileMetadata(String fileId, User user) {
        return fileMetadataRepository.findByIdAndUser(fileId, user)
                .orElseThrow(() -> new FileNotFoundException("File not found with ID: " + fileId));
    }

    @Override
    @Transactional(readOnly = true)
    public FileMetadata getSharedFileMetadata(String publicLinkId) {
        FileMetadata fileMetadata = fileMetadataRepository.findByPublicLinkId(publicLinkId)
                .orElseThrow(() -> new FileNotFoundException("Shared file not found with link ID: " + publicLinkId));

        // Check if link is expired
        if (fileMetadata.getPublicLinkExpiresAt() != null &&
            fileMetadata.getPublicLinkExpiresAt().isBefore(LocalDateTime.now())) {
            throw new FileNotFoundException("Shared link has expired");
        }

        if (!Boolean.TRUE.equals(fileMetadata.getIsPublic())) {
            throw new FileNotFoundException("File is not publicly accessible");
        }

        return fileMetadata;
    }
}
