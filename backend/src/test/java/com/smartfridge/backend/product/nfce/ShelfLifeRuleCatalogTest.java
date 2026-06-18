package com.smartfridge.backend.product.nfce;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Optional;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ShelfLifeRuleCatalogTest {

    private final ShelfLifeRuleCatalog catalog = new ShelfLifeRuleCatalog(new ObjectMapper());

    @Test
    void shouldResolveExactMatchFromCentralCatalog() {
        Optional<ShelfLifeSuggestionMatch> match = catalog.resolve("Arroz");

        assertTrue(match.isPresent());
        assertEquals("nfce-shelf-life-v1", match.get().catalogVersion());
        assertEquals(ShelfLifeMatchType.EXACT, match.get().matchType());
        assertEquals("ARROZ_180_DIAS", match.get().suggestion().ruleCode());
        assertEquals(180, match.get().suggestion().shelfLifeDays());
    }

    @Test
    void shouldResolvePartialMatchFromCentralCatalog() {
        Optional<ShelfLifeSuggestionMatch> match = catalog.resolve("Iogurte Natural Integral");

        assertTrue(match.isPresent());
        assertEquals(ShelfLifeMatchType.PARTIAL, match.get().matchType());
        assertEquals("IOGURTE_15_DIAS", match.get().suggestion().ruleCode());
        assertEquals(15, match.get().suggestion().shelfLifeDays());
    }

    @Test
    void shouldReturnEmptyWhenNoRuleMatches() {
        Optional<ShelfLifeSuggestionMatch> match = catalog.resolve("Chocolate meio amargo");

        assertFalse(match.isPresent());
    }
}
