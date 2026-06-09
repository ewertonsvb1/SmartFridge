package com.smartfridge.backend.dashboard.dto;

public record DashboardResponse(
        FridgeDashboardResponse fridge,
        AgendaDashboardResponse agenda,
        HouseBillsDashboardResponse houseBills
) {
}
