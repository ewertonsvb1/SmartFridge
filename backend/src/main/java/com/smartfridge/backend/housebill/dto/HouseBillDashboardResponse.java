package com.smartfridge.backend.housebill.dto;

import java.math.BigDecimal;

public record HouseBillDashboardResponse(
        long totalCount,
        long openCount,
        long overdueCount,
        long paidCount,
        BigDecimal totalAmount,
        BigDecimal openAmount,
        BigDecimal overdueAmount,
        BigDecimal paidAmount
) {
}
