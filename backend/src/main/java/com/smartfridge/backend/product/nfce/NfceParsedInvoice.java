package com.smartfridge.backend.product.nfce;

import java.time.LocalDate;
import java.util.List;

record NfceParsedInvoice(
        String sourceUrl,
        String accessKey,
        String noteNumber,
        LocalDate emissionDate,
        List<NfceParsedInvoiceItem> items
) {
}
