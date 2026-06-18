package com.smartfridge.backend.product.nfce.dto;

import java.time.LocalDate;
import java.util.List;

public record NfceImportPreviewResponse(
        String sourceUrl,
        String accessKey,
        String noteNumber,
        LocalDate emissionDate,
        List<NfceImportPreviewItemResponse> items
) {
}
