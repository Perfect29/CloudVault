package com.cloudvault.filestorage.service;

import com.cloudvault.filestorage.entity.User;

public interface UserService {
    User findById(String userId);
    
    User findByUsername(String username);
    
    User findByEmail(String email);
    
    boolean existsByUsername(String username);
    
    boolean existsByEmail(String email);
    
    User createUser(String username, String email, String password);
    
    User updateUser(User user);
}