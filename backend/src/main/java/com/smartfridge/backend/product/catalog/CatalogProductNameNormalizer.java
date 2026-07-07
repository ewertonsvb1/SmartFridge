package com.smartfridge.backend.product.catalog;

import com.smartfridge.backend.common.exception.BusinessException;
import java.text.Normalizer;
import java.util.Locale;
import org.springframework.stereotype.Component;

@Component
public class CatalogProductNameNormalizer {

    public String normalize(String rawName) {
        if (rawName == null) {
            throw new BusinessException("Catalog product name is required");
        }

        String trimmed = rawName.trim().replaceAll("\\s+", " ");
        if (trimmed.isBlank()) {
            throw new BusinessException("Catalog product name is required");
        }

        String withoutAccents = Normalizer.normalize(trimmed, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "");

        return withoutAccents.toLowerCase(Locale.ROOT);
    }
}
