package com.smartfridge.backend.dashboard.dto;

public record HouseBillsDashboardResponse(
        boolean implemented,
        long totalOpen,
        long overdue,
        long paid
) {
}
