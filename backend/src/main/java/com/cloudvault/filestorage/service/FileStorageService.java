package com.cloudvault.filestorage.service;

import com.cloudvault.filestorage.exception.FileStorageException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@Service
public class FileStorageService {

    @Value("${file.storage.local.path:./uploads}")
    private String uploadDir;

    private static final List<String> ALLOWED_EXTENSIONS = Arrays.asList(
            ".jpg", ".jpeg", ".png", ".gif", ".pdf", ".doc", ".docx", 
            ".xls", ".xlsx", ".ppt", ".pptx", ".txt", ".zip", ".rar"
    );

    public String storeFile(MultipartFile file) throws IOException {
        validateFile(file);

        // Create upload directory if it doesn't exist
        Path uploadPath = Paths.get(uploadDir);
        if (!Files.exists(uploadPath)) {
            try {
                Files.createDirectories(uploadPath);
            } catch (IOException ex) {
                throw new FileStorageException("Could not create upload directory", ex);
            }
        }

        // Generate unique filename
        String rawName = file.getOriginalFilename();
        String originalFilename = StringUtils.cleanPath(rawName);
        String fileExtension = "";
        if (originalFilename.contains(".")) {
            fileExtension = originalFilename.substring(originalFilename.lastIndexOf(".")).toLowerCase();
        }
        
        // Validate file extension
        if (!ALLOWED_EXTENSIONS.contains(fileExtension)) {
            throw new FileStorageException("File type not allowed: " + fileExtension);
        }

        String uniqueFilename = UUID.randomUUID().toString() + fileExtension;

        // Copy file to the target location
        Path targetLocation = uploadPath.resolve(uniqueFilename);
        try {
            Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException ex) {
            throw new FileStorageException("Failed to store file " + originalFilename, ex);
        }

        return uniqueFilename;
    }

    private void validateFile(MultipartFile file) {
        if (file.isEmpty()) {
            throw new FileStorageException("Cannot store empty file");
        }

        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || originalFilename.trim().isEmpty()) {
            throw new FileStorageException("File must have a valid name");
        }

        // Check for path traversal attacks
        if (originalFilename.contains("..")) {
            throw new FileStorageException("Filename contains invalid path sequence: " + originalFilename);
        }

        // Check file size (100MB limit)
        if (file.getSize() > 100 * 1024 * 1024) {
            throw new FileStorageException("File size exceeds maximum limit of 100MB");
        }
    }

    public Resource loadFileAsResource(String fileName) throws IOException {
        if (fileName == null || fileName.trim().isEmpty()) {
            throw new FileStorageException("Filename cannot be null or empty");
        }

        // Check for path traversal attacks
        if (fileName.contains("..")) {
            throw new FileStorageException("Filename contains invalid path sequence: " + fileName);
        }

        try {
            Path filePath = Paths.get(uploadDir).resolve(fileName).normalize();
            Resource resource = new UrlResource(filePath.toUri());
            
            if (resource.exists() && resource.isReadable()) {
                return resource;
            } else {
                throw new FileStorageException("File not found or not readable: " + fileName);
            }
        } catch (MalformedURLException ex) {
            throw new FileStorageException("Invalid file path: " + fileName, ex);
        }
    }

    public void deleteFile(String fileName) throws IOException {
        if (fileName == null || fileName.trim().isEmpty()) {
            throw new FileStorageException("Filename cannot be null or empty");
        }

        // Check for path traversal attacks
        if (fileName.contains("..")) {
            throw new FileStorageException("Filename contains invalid path sequence: " + fileName);
        }

        try {
            Path filePath = Paths.get(uploadDir).resolve(fileName).normalize();
            boolean deleted = Files.deleteIfExists(filePath);
            if (!deleted) {
                throw new FileStorageException("File not found for deletion: " + fileName);
            }
        } catch (IOException ex) {
            throw new FileStorageException("Failed to delete file: " + fileName, ex);
        }
    }
}