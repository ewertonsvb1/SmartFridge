package com.smartfridge.backend.notification.dto;

import com.smartfridge.backend.notification.NotificationType;
import java.time.Instant;
import java.time.LocalDate;

public record NotificationResponse(
        Long id,
        NotificationType type,
        LocalDate eventDate,
        String sourceModule,
        Long sourceId,
        String sourceLabel,
        LocalDate sourceDate,
        Long productId,
        String productName,
        LocalDate productExpirationDate,
        Instant createdAt
) {
}
