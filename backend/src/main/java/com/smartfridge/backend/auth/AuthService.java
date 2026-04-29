package com.smartfridge.backend.auth;

import com.smartfridge.backend.auth.dto.AuthResponse;
import com.smartfridge.backend.auth.dto.LoginRequest;
import com.smartfridge.backend.auth.dto.RegisterRequest;
import com.smartfridge.backend.common.exception.BusinessException;
import com.smartfridge.backend.security.JwtService;
import com.smartfridge.backend.security.UserPrincipal;
import com.smartfridge.backend.user.UserEntity;
import com.smartfridge.backend.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new BusinessException("Email already in use");
        }

        UserEntity user = new UserEntity();
        user.setName(request.name());
        user.setEmail(request.email().toLowerCase());
        user.setPassword(passwordEncoder.encode(request.password()));

        UserEntity saved = userRepository.save(user);
        UserPrincipal principal = new UserPrincipal(saved.getId(), saved.getEmail(), saved.getPassword());
        return new AuthResponse(jwtService.generateToken(principal));
    }

    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.email().toLowerCase(), request.password()));

        UserEntity user = userRepository.findByEmail(request.email().toLowerCase())
                .orElseThrow(() -> new BusinessException("Invalid credentials"));

        UserPrincipal principal = new UserPrincipal(user.getId(), user.getEmail(), user.getPassword());
        return new AuthResponse(jwtService.generateToken(principal));
    }
}
