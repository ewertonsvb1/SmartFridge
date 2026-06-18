package com.smartfridge.backend.product.nfce.dto;

import com.smartfridge.backend.product.dto.ProductResponse;
import java.util.List;

public record NfceImportConfirmResponse(
        int createdCount,
        List<ProductResponse> products
) {
}
