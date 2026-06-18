package com.smartfridge.backend.product.nfce.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record NfceImportConfirmItemRequest(
        @NotBlank(message = "Item name is required") String name,
        @NotNull(message = "Item quantity is required") @Min(value = 1, message = "Item quantity must be positive") Integer quantity,
        @NotNull(message = "Manufacture date is required") LocalDate manufactureDate,
        @NotNull(message = "Expiration date is required") LocalDate expirationDate
) {
}
