package com.smartfridge.backend.shopping.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record ShoppingListUpdateRequest(
        @NotBlank(message = "Name is required") String name,
        @NotNull(message = "Quantity is required") @Min(value = 1, message = "Quantity must be positive") Integer quantity,
        @NotNull(message = "Checked is required") Boolean checked
) {
}
