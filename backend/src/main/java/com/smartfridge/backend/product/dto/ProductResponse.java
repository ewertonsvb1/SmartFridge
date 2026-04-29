package com.smartfridge.backend.product.dto;

import com.smartfridge.backend.product.ProductStatus;
import java.time.Instant;
import java.time.LocalDate;

public record ProductResponse(
        Long id,
        String name,
        Integer quantity,
        LocalDate manufactureDate,
        LocalDate expirationDate,
        ProductStatus status,
        Long userId,
        Instant createdAt
) {
}
