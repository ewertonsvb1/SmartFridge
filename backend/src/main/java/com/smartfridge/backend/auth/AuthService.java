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
import lombok.extern.slf4j.Slf4j;

import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    public AuthResponse register(RegisterRequest request) {

        log.info("Entrou em register: {}", request.email());

        if (userRepository.existsByEmail(request.email())) {
            log.warn("Email já existe: {}", request.email());
            throw new BusinessException("Email already in use");
        }

        UserEntity user = new UserEntity();

        user.setName(request.name());
        user.setEmail(request.email().toLowerCase());

        log.info("Antes de criptografar senha");

        user.setPassword(
                passwordEncoder.encode(request.password())
        );

        log.info("Antes de salvar usuário");

        UserEntity saved =
                userRepository.save(user);

        log.info("Usuário salvo com id={}", saved.getId());

        UserPrincipal principal =
                new UserPrincipal(
                        saved.getId(),
                        saved.getEmail(),
                        saved.getPassword()
                );

        log.info("Antes de gerar JWT");

        String token =
                jwtService.generateToken(principal);

        log.info("JWT gerado");

        return new AuthResponse(token);
    }

    public AuthResponse login(LoginRequest request) {

        log.info("Tentando login: {}", request.email());

        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.email().toLowerCase(),
                        request.password()
                )
        );

        UserEntity user =
                userRepository.findByEmail(
                                request.email().toLowerCase())
                        .orElseThrow(
                                () -> new BusinessException(
                                        "Invalid credentials"
                                )
                        );

        log.info("Login realizado id={}", user.getId());

        UserPrincipal principal =
                new UserPrincipal(
                        user.getId(),
                        user.getEmail(),
                        user.getPassword()
                );

        return new AuthResponse(
                jwtService.generateToken(principal)
        );
    }
}