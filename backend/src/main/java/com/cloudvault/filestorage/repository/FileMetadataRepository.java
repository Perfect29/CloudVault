package com.cloudvault.filestorage.repository;

import com.cloudvault.filestorage.entity.FileMetadata;
import com.cloudvault.filestorage.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FileMetadataRepository extends JpaRepository<FileMetadata, String> {
    List<FileMetadata> findByUserOrderByCreatedAtDesc(User user);
    
    Page<FileMetadata> findByUserOrderByCreatedAtDesc(User user, Pageable pageable);
    
    @Query("SELECT f FROM FileMetadata f WHERE f.user = :user AND " +
           "(LOWER(f.filename) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(f.originalFilename) LIKE LOWER(CONCAT('%', :search, '%')))")
    Page<FileMetadata> findByUserAndFilenameContainingIgnoreCase(
        @Param("user") User user, 
        @Param("search") String search, 
        Pageable pageable
    );
    
    Optional<FileMetadata> findByPublicLinkId(String publicLinkId);
    
    Optional<FileMetadata> findByIdAndUser(String id, User user);
    
    @Query("SELECT SUM(f.fileSize) FROM FileMetadata f WHERE f.user = :user")
    Long getTotalFileSizeByUser(@Param("user") User user);
    
    Long countByUser(User user);
}