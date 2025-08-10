package com.cloudvault.filestorage.controller;

import com.cloudvault.filestorage.dto.LoginRequest;
import com.cloudvault.filestorage.dto.SignupRequest;
import com.cloudvault.filestorage.entity.User;
import com.cloudvault.filestorage.security.JwtUtils;
import com.cloudvault.filestorage.security.UserPrincipal;
import com.cloudvault.filestorage.service.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/auth")
public class AuthController {
    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private UserService userService;

    @Autowired
    private JwtUtils jwtUtils;

    @Value("${app.auth.allow-demo-any-password:false}")
    private boolean allowDemoAnyPassword;

    @PostMapping("/signin")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody LoginRequest loginRequest) {
        String principal = loginRequest.getUsername();
        if (principal == null || principal.isBlank()) {
            principal = loginRequest.getEmail();
        }
        // Dev/demo convenience: allow any password for demo users
        if (allowDemoAnyPassword) {
            String p = principal != null ? principal.toLowerCase() : "";
            boolean isDemoUser = "demo@cloudvault.com".equals(p) || "test@example.com".equals(p)
                    || "demo".equals(p) || "testuser".equals(p);
            if (isDemoUser) {
                User user = p.contains("@") ? userService.findByEmail(p) : userService.findByUsername(p);
                UserPrincipal userDetails = UserPrincipal.create(user);
                UsernamePasswordAuthenticationToken devAuth = new UsernamePasswordAuthenticationToken(
                        userDetails, null, userDetails.getAuthorities());
                SecurityContextHolder.getContext().setAuthentication(devAuth);
                return buildJwtResponse(devAuth);
            }
        }

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(principal, loginRequest.getPassword()));

        SecurityContextHolder.getContext().setAuthentication(authentication);
        return buildJwtResponse(authentication);
    }

    private ResponseEntity<?> buildJwtResponse(Authentication authentication) {
        String jwt = jwtUtils.generateJwtToken(authentication);
        UserPrincipal userDetails = (UserPrincipal) authentication.getPrincipal();

        Map<String, Object> userInfo = new HashMap<>();
        userInfo.put("id", userDetails.getId());
        userInfo.put("username", userDetails.getUsername());
        userInfo.put("email", userDetails.getEmail());

        Map<String, Object> response = new HashMap<>();
        response.put("token", jwt);
        response.put("user", userInfo);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/signup")
    public ResponseEntity<Map<String, String>> registerUser(@Valid @RequestBody SignupRequest signUpRequest) {
        User user = userService.createUser(
                signUpRequest.getUsername(),
                signUpRequest.getEmail(),
                signUpRequest.getPassword()
        );

        Map<String, String> response = new HashMap<>();
        response.put("message", "User registered successfully!");
        response.put("userId", user.getId());
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();

        Map<String, Object> userInfo = new HashMap<>();
        userInfo.put("id", userPrincipal.getId());
        userInfo.put("username", userPrincipal.getUsername());
        userInfo.put("email", userPrincipal.getEmail());

        return ResponseEntity.ok(userInfo);
    }
}