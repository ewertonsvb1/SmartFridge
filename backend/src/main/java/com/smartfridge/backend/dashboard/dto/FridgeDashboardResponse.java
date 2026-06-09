package com.smartfridge.backend.dashboard.dto;

public record FridgeDashboardResponse(
        long total,
        long expired,
        long nearExpiration
) {
}
