package com.smartfridge.backend.housebill.dto;

import com.smartfridge.backend.housebill.HouseBillStatus;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

public record HouseBillResponse(
        Long id,
        String description,
        BigDecimal amount,
        LocalDate dueDate,
        String category,
        HouseBillStatus status,
        LocalDate paidAt,
        Long userId,
        Instant createdAt
) {
}
