package com.cloudvault.filestorage.security;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.event.annotation.BeforeTestMethod;

public class WithMockJwt {
    @BeforeTestMethod
    public void setupAuth() {
        UserPrincipal principal = new UserPrincipal("user-123", "testuser", "test@example.com", "password");
        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);
    }
}


