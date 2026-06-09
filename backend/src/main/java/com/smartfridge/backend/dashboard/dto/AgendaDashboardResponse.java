package com.smartfridge.backend.dashboard.dto;

public record AgendaDashboardResponse(
        boolean implemented,
        long total,
        long today,
        long upcoming
) {
}
