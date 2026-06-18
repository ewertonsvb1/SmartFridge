package com.smartfridge.backend.product.nfce;

import java.util.Optional;

public interface ShelfLifeSuggestionResolver {

    Optional<ShelfLifeSuggestionMatch> resolve(String description);
}
