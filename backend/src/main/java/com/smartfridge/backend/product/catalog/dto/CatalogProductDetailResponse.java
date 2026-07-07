package com.smartfridge.backend.product.catalog.dto;

public record CatalogProductDetailResponse(
        Long id,
        String name,
        String brand,
        String category,
        String defaultUnit,
        Integer defaultQuantity,
        String barcode
) {
}
