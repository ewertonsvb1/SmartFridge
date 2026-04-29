package com.smartfridge.backend.shopping.dto;

import java.time.Instant;

public record ShoppingListResponse(
        Long id,
        String name,
        Integer quantity,
        boolean checked,
        Long userId,
        Instant createdAt
) {
}
