package com.smartfridge.backend.product.nfce.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record NfceImportPreviewItemResponse(
        int lineNumber,
        String description,
        BigDecimal quantity,
        LocalDate suggestedManufactureDate,
        LocalDate suggestedExpirationDate,
        Integer suggestedShelfLifeDays,
        String shelfLifeRuleCode,
        boolean manualReviewRequired
) {
}
