package com.smartfridge.backend.product.nfce;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.io.InputStream;
import java.text.Normalizer;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import lombok.Getter;
import org.springframework.stereotype.Component;

@Component
public class ShelfLifeRuleCatalog {

    private static final String RESOURCE_PATH = "/product/nfce/shelf-life-rules.json";

    @Getter
    private final String version;

    private final List<ShelfLifeRuleDefinition> rules;

    public ShelfLifeRuleCatalog(ObjectMapper objectMapper) {
        ShelfLifeRuleCatalogDocument document = loadDocument(objectMapper);
        this.version = document.version();
        this.rules = List.copyOf(document.rules());
    }

    public Optional<ShelfLifeSuggestionMatch> resolve(String description) {
        String normalizedDescription = normalize(description);
        if (normalizedDescription.isBlank()) {
            return Optional.empty();
        }

        return findMatch(normalizedDescription, true)
                .or(() -> findMatch(normalizedDescription, false));
    }

    private Optional<ShelfLifeSuggestionMatch> findMatch(
            String normalizedDescription,
            boolean exactMatch
    ) {
        return rules.stream()
                .filter(rule -> {
                    String normalizedKeyword = normalize(rule.keyword());
                    return exactMatch
                            ? normalizedDescription.equals(normalizedKeyword)
                            : normalizedDescription.contains(normalizedKeyword);
                })
                .findFirst()
                .map(rule -> new ShelfLifeSuggestionMatch(
                        version,
                        rule.keyword(),
                        exactMatch ? ShelfLifeMatchType.EXACT : ShelfLifeMatchType.PARTIAL,
                        new ShelfLifeSuggestion(rule.ruleCode(), rule.shelfLifeDays())
                ));
    }

    private ShelfLifeRuleCatalogDocument loadDocument(ObjectMapper objectMapper) {
        try (InputStream inputStream = ShelfLifeRuleCatalog.class.getResourceAsStream(RESOURCE_PATH)) {
            if (inputStream == null) {
                throw new IllegalStateException("Shelf life catalog resource not found: " + RESOURCE_PATH);
            }
            return objectMapper.readValue(inputStream, ShelfLifeRuleCatalogDocument.class);
        } catch (IOException e) {
            throw new IllegalStateException("Failed to load shelf life catalog", e);
        }
    }

    private String normalize(String value) {
        if (value == null) {
            return "";
        }

        String normalized = Normalizer.normalize(value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "");
        return normalized.toLowerCase(Locale.ROOT).trim();
    }

    record ShelfLifeRuleCatalogDocument(String version, List<ShelfLifeRuleDefinition> rules) {
    }

    record ShelfLifeRuleDefinition(String keyword, String ruleCode, int shelfLifeDays) {
    }
}
