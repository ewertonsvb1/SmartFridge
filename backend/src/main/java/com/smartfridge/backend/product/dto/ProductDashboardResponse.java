package com.smartfridge.backend.product.dto;

public record ProductDashboardResponse(long total, long expired, long nearExpiration) {
}
