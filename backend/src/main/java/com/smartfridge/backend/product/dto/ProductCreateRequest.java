package com.smartfridge.backend.product.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record ProductCreateRequest(
        @NotBlank(message = "Name is required") String name,
        @NotNull(message = "Quantity is required") @Min(value = 1, message = "Quantity must be positive") Integer quantity,
        @NotNull(message = "Manufacture date is required") LocalDate manufactureDate,
        @NotNull(message = "Expiration date is required") LocalDate expirationDate
) {
}
