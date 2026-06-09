package com.smartfridge.backend.agenda.dto;

import com.smartfridge.backend.agenda.AgendaEventStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDateTime;

public record AgendaEventCreateRequest(
        @NotBlank(message = "Title is required") String title,
        String description,
        @NotNull(message = "Start time is required") LocalDateTime startAt,
        @NotNull(message = "End time is required") LocalDateTime endAt,
        @NotNull(message = "Status is required") AgendaEventStatus status
) {
}
