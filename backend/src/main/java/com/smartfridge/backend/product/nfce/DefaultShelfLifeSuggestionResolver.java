package com.smartfridge.backend.product.nfce;

import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class DefaultShelfLifeSuggestionResolver implements ShelfLifeSuggestionResolver {

    private final ShelfLifeRuleCatalog shelfLifeRuleCatalog;

    @Override
    public Optional<ShelfLifeSuggestionMatch> resolve(String description) {
        return shelfLifeRuleCatalog.resolve(description);
    }
}
