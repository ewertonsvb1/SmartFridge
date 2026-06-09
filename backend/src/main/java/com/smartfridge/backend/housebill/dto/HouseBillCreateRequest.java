package com.smartfridge.backend.housebill.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;

public record HouseBillCreateRequest(
        @NotBlank(message = "Description is required") String description,
        @NotNull(message = "Amount is required") @DecimalMin(value = "0.01", inclusive = true) BigDecimal amount,
        @NotNull(message = "Due date is required") LocalDate dueDate,
        String category
) {
}
