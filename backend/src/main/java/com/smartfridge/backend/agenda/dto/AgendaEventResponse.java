package com.smartfridge.backend.agenda.dto;

import com.smartfridge.backend.agenda.AgendaEventStatus;
import java.time.Instant;
import java.time.LocalDateTime;

public record AgendaEventResponse(
        Long id,
        String title,
        String description,
        LocalDateTime startAt,
        LocalDateTime endAt,
        AgendaEventStatus status,
        Long userId,
        Instant createdAt
) {
}
