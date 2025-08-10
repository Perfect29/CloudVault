package com.cloudvault.filestorage.service;

import com.cloudvault.filestorage.dto.FileResponse;
import com.cloudvault.filestorage.entity.FileMetadata;
import com.cloudvault.filestorage.entity.User;
import org.springframework.core.io.Resource;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

public interface FileService {
    FileResponse uploadFile(MultipartFile file, User user) throws IOException;
    
    Page<FileMetadata> getUserFiles(User user, String search, Pageable pageable);
    
    Resource downloadFile(String fileId, User user) throws IOException;
    
    Map<String, Object> createShareLink(String fileId, Integer expirationHours, User user);
    
    Resource downloadSharedFile(String publicLinkId) throws IOException;
    
    void deleteFile(String fileId, User user) throws IOException;
    
    Map<String, Object> getUserStats(User user);
    
    FileMetadata getFileMetadata(String fileId, User user);
    
    FileMetadata getSharedFileMetadata(String publicLinkId);
}