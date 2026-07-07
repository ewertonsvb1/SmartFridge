package com.smartfridge.backend.product.catalog;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.smartfridge.backend.common.exception.BusinessException;
import org.junit.jupiter.api.Test;

class CatalogProductNameNormalizerTest {

    private final CatalogProductNameNormalizer normalizer = new CatalogProductNameNormalizer();

    @Test
    void shouldNormalizeSpacesCaseAndAccents() {
        String normalized = normalizer.normalize("  Leité   ITALÁC  ");

        assertEquals("leite italac", normalized);
    }

    @Test
    void shouldRejectBlankName() {
        assertThrows(BusinessException.class, () -> normalizer.normalize("   "));
    }
}
