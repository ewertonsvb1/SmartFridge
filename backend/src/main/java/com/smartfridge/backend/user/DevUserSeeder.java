package com.smartfridge.backend.user;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@Profile("dev")
@RequiredArgsConstructor
public class DevUserSeeder implements CommandLineRunner {

    private static final String DEV_NAME = "Usuario Demo";
    private static final String DEV_EMAIL = "demo@smartfridge.local";
    private static final String DEV_PASSWORD = "123456";

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        if (userRepository.existsByEmail(DEV_EMAIL)) {
            return;
        }

        UserEntity user = new UserEntity();
        user.setName(DEV_NAME);
        user.setEmail(DEV_EMAIL);
        user.setPassword(passwordEncoder.encode(DEV_PASSWORD));
        userRepository.save(user);
    }
}
