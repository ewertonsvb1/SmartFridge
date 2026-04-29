package com.smartfridge.backend.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank(message = "Name is required") String name,
        @Email(message = "Email is invalid") @NotBlank(message = "Email is required") String email,
        @Size(min = 6, message = "Password must have at least 6 characters") String password
) {
}
