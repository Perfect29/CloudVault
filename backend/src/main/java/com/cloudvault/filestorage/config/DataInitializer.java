package com.cloudvault.filestorage.config;

import com.cloudvault.filestorage.entity.User;
import com.cloudvault.filestorage.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@Profile({"dev", "test", "docker"})
public class DataInitializer implements CommandLineRunner {
    private static final Logger log = LoggerFactory.getLogger(DataInitializer.class);

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public DataInitializer(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        seedUser("demo", "demo@cloudvault.com", "demo");
        seedUser("testuser", "test@example.com", "test");
    }

    private void seedUser(String username, String email, String rawPassword) {
        if (userRepository.findByEmail(email).isEmpty()) {
            User user = new User(username, email, passwordEncoder.encode(rawPassword));
            userRepository.save(user);
            log.info("Seeded user {} ({})", username, email);
        }
    }
}


