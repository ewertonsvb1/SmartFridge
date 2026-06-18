package com.smartfridge.backend.product.nfce;

public record ShelfLifeSuggestionMatch(
        String catalogVersion,
        String keyword,
        ShelfLifeMatchType matchType,
        ShelfLifeSuggestion suggestion
) {
}
