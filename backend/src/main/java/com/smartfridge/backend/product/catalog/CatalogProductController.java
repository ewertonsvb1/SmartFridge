package com.smartfridge.backend.product.catalog;

import com.smartfridge.backend.product.catalog.dto.CatalogProductDetailResponse;
import com.smartfridge.backend.product.catalog.dto.CatalogProductSuggestionResponse;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/products/catalog")
@RequiredArgsConstructor
public class CatalogProductController {

    private final CatalogProductService catalogProductService;

    @GetMapping("/search")
    public ResponseEntity<List<CatalogProductSuggestionResponse>> search(@RequestParam("q") String query) {
        return ResponseEntity.ok(catalogProductService.searchSuggestions(query));
    }

    @GetMapping("/{id}")
    public ResponseEntity<CatalogProductDetailResponse> getById(@PathVariable Long id) {
        return ResponseEntity.ok(catalogProductService.findDetailById(id));
    }

    @GetMapping("/barcode/{barcode}")
    public ResponseEntity<CatalogProductSuggestionResponse> findByBarcode(@PathVariable String barcode) {
        return ResponseEntity.ok(catalogProductService.findSuggestionByBarcode(barcode));
    }
}
