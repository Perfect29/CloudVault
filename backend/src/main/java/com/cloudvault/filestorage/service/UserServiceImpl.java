package com.cloudvault.filestorage.service;

import com.cloudvault.filestorage.entity.User;
import com.cloudvault.filestorage.exception.UserNotFoundException;
import com.cloudvault.filestorage.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class UserServiceImpl implements UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    @Transactional(readOnly = true)
    public User findById(String userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
    }

    @Override
    @Transactional(readOnly = true)
    public User findByUsername(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new UserNotFoundException("User not found with username: " + username));
    }

    @Override
    @Transactional(readOnly = true)
    public User findByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException("User not found with email: " + email));
    }

    @Override
    @Transactional(readOnly = true)
    public boolean existsByUsername(String username) {
        return userRepository.existsByUsername(username);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean existsByEmail(String email) {
        return userRepository.existsByEmail(email);
    }

    @Override
    public User createUser(String username, String email, String password) {
        if (existsByUsername(username)) {
            throw new IllegalArgumentException("Username is already taken");
        }
        if (existsByEmail(email)) {
            throw new IllegalArgumentException("Email is already in use");
        }
        User user = new User(username, email, passwordEncoder.encode(password));
        return userRepository.save(user);
    }

    @Override
    public User updateUser(User user) {
        if (user.getId() == null) {
            throw new IllegalArgumentException("User ID cannot be null for update");
        }
        // Verify user exists
        findById(user.getId());
        return userRepository.save(user);
    }
}
