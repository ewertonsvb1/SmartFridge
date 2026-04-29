package com.smartfridge.backend.notification.dto;

import com.smartfridge.backend.notification.NotificationType;
import java.time.Instant;
import java.time.LocalDate;

public record NotificationResponse(
        Long id,
        NotificationType type,
        LocalDate eventDate,
        Long productId,
        String productName,
        LocalDate productExpirationDate,
        Instant createdAt
) {
}