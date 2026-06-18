package com.smartfridge.backend.product.nfce.dto;

import jakarta.validation.constraints.NotBlank;

public record NfceImportPreviewRequest(
        @NotBlank(message = "QR Code payload is required") String qrCodePayload
) {
}
