package com.smartfridge.backend.product.nfce;

import java.math.BigDecimal;

record NfceParsedInvoiceItem(
        int lineNumber,
        String description,
        BigDecimal quantity
) {
}
