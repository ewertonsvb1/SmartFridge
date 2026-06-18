package com.smartfridge.backend.product.nfce.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.util.List;

public record NfceImportConfirmRequest(
        @NotEmpty(message = "At least one item must be selected for import")
        List<@NotNull(message = "Imported item is required") @Valid NfceImportConfirmItemRequest> items
) {
}
