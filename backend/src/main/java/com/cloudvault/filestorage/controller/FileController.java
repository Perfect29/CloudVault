package com.cloudvault.filestorage.controller;

import com.cloudvault.filestorage.dto.FileResponse;
import com.cloudvault.filestorage.entity.FileMetadata;
import com.cloudvault.filestorage.entity.User;
import com.cloudvault.filestorage.security.UserPrincipal;
import com.cloudvault.filestorage.service.FileService;
import com.cloudvault.filestorage.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/files")
public class FileController {

    @Autowired
    private FileService fileService;

    @Autowired
    private UserService userService;

    @PostMapping("/upload")
    public ResponseEntity<FileResponse> uploadFile(@RequestParam("file") MultipartFile file,
                                                 Authentication authentication) throws IOException {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        User user = userService.findById(userPrincipal.getId());

        FileResponse fileResponse = fileService.uploadFile(file, user);
        return ResponseEntity.ok(fileResponse);
    }

    @GetMapping
    public ResponseEntity<Map<String, Object>> getUserFiles(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String search,
            Authentication authentication) {

        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        User user = userService.findById(userPrincipal.getId());

        Pageable pageable = PageRequest.of(page, size);
        Page<FileMetadata> filesPage = fileService.getUserFiles(user, search, pageable);

        List<FileResponse> files = filesPage.getContent().stream()
                .map(FileResponse::new)
                .collect(Collectors.toList());

        Map<String, Object> response = new HashMap<>();
        response.put("files", files);
        response.put("currentPage", filesPage.getNumber());
        response.put("totalItems", filesPage.getTotalElements());
        response.put("totalPages", filesPage.getTotalPages());

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{fileId}/download")
    public ResponseEntity<Resource> downloadFile(@PathVariable String fileId,
                                               Authentication authentication) throws IOException {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        User user = userService.findById(userPrincipal.getId());

        FileMetadata fileMetadata = fileService.getFileMetadata(fileId, user);
        Resource resource = fileService.downloadFile(fileId, user);

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(fileMetadata.getContentType()))
                .header(HttpHeaders.CONTENT_DISPOSITION, 
                       "attachment; filename=\"" + fileMetadata.getOriginalFilename() + "\"")
                .body(resource);
    }

    @PostMapping("/{fileId}/share")
    public ResponseEntity<Map<String, Object>> createShareLink(@PathVariable String fileId,
                                                             @RequestParam(required = false) Integer expirationHours,
                                                             Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        User user = userService.findById(userPrincipal.getId());

        Map<String, Object> response = fileService.createShareLink(fileId, expirationHours, user);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/share/{publicLinkId}")
    public ResponseEntity<Resource> downloadSharedFile(@PathVariable String publicLinkId) throws IOException {
        FileMetadata fileMetadata = fileService.getSharedFileMetadata(publicLinkId);
        Resource resource = fileService.downloadSharedFile(publicLinkId);

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(fileMetadata.getContentType()))
                .header(HttpHeaders.CONTENT_DISPOSITION, 
                       "attachment; filename=\"" + fileMetadata.getOriginalFilename() + "\"")
                .body(resource);
    }

    @DeleteMapping("/{fileId}")
    public ResponseEntity<Map<String, String>> deleteFile(@PathVariable String fileId,
                                                         Authentication authentication) throws IOException {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        User user = userService.findById(userPrincipal.getId());

        fileService.deleteFile(fileId, user);
        return ResponseEntity.ok(Map.of("message", "File deleted successfully"));
    }

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getUserStats(Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        User user = userService.findById(userPrincipal.getId());

        Map<String, Object> stats = fileService.getUserStats(user);
        return ResponseEntity.ok(stats);
    }
}