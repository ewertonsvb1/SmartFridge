package com.smartfridge.backend.product.catalog;

import com.smartfridge.backend.common.exception.BusinessException;
import com.smartfridge.backend.common.exception.ResourceNotFoundException;
import com.smartfridge.backend.product.catalog.dto.CatalogProductDetailResponse;
import com.smartfridge.backend.product.catalog.dto.CatalogProductSuggestionResponse;
import java.util.List;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CatalogProductService {

    private static final int MIN_QUERY_LENGTH = 2;
    private static final int MAX_SUGGESTIONS = 10;

    private final CatalogProductRepository catalogProductRepository;
    private final CatalogProductNameNormalizer catalogProductNameNormalizer;

    @Transactional(readOnly = true)
    public Optional<CatalogProduct> findByNormalizedName(String normalizedName) {
        return catalogProductRepository.findByNormalizedName(normalizedName);
    }

    @Transactional(readOnly = true)
    public Optional<CatalogProduct> findByBarcode(String barcode) {
        return catalogProductRepository.findByBarcode(normalizeBarcode(barcode));
    }

    @Transactional
    public CatalogProduct create(
            String name,
            String normalizedName,
            String brand,
            String category,
            String defaultUnit,
            Integer defaultQuantity,
            String barcode
    ) {
        CatalogProduct product = new CatalogProduct();
        product.setName(compactText(name));
        product.setNormalizedName(normalizedName);
        product.setBrand(sanitizeOptionalText(brand));
        product.setCategory(sanitizeOptionalText(category));
        product.setDefaultUnit(sanitizeOptionalText(defaultUnit));
        product.setDefaultQuantity(sanitizeOptionalInteger(defaultQuantity));
        product.setBarcode(normalizeBarcode(barcode));
        return catalogProductRepository.save(product);
    }

    @Transactional(readOnly = true)
    public List<CatalogProductSuggestionResponse> searchSuggestions(String query) {
        String normalizedQuery = catalogProductNameNormalizer.normalize(query);
        if (normalizedQuery.length() < MIN_QUERY_LENGTH) {
            throw new BusinessException("Search term must have at least 2 characters");
        }

        return catalogProductRepository.searchOrdered(
                        normalizedQuery,
                        PageRequest.of(0, MAX_SUGGESTIONS))
                .stream()
                .map(product -> new CatalogProductSuggestionResponse(product.getId(), product.getName()))
                .toList();
    }

    @Transactional(readOnly = true)
    public CatalogProductSuggestionResponse findSuggestionByBarcode(String barcode) {
        return findByBarcode(barcode)
                .map(product -> new CatalogProductSuggestionResponse(product.getId(), product.getName()))
                .orElseThrow(() -> new ResourceNotFoundException("Barcode not found"));
    }

    @Transactional(readOnly = true)
    public CatalogProductDetailResponse findDetailById(Long id) {
        CatalogProduct product = catalogProductRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Catalog product not found"));
        return toDetailResponse(product);
    }

    @Transactional
    public CatalogProduct enrichIfMissing(
            CatalogProduct product,
            String brand,
            String category,
            String defaultUnit,
            Integer defaultQuantity,
            String barcode
    ) {
        boolean changed = false;

        if (isBlank(product.getBrand())) {
            String sanitizedBrand = sanitizeOptionalText(brand);
            if (sanitizedBrand != null) {
                product.setBrand(sanitizedBrand);
                changed = true;
            }
        }

        if (isBlank(product.getCategory())) {
            String sanitizedCategory = sanitizeOptionalText(category);
            if (sanitizedCategory != null) {
                product.setCategory(sanitizedCategory);
                changed = true;
            }
        }

        if (isBlank(product.getDefaultUnit())) {
            String sanitizedDefaultUnit = sanitizeOptionalText(defaultUnit);
            if (sanitizedDefaultUnit != null) {
                product.setDefaultUnit(sanitizedDefaultUnit);
                changed = true;
            }
        }

        if (product.getDefaultQuantity() == null) {
            Integer sanitizedDefaultQuantity = sanitizeOptionalInteger(defaultQuantity);
            if (sanitizedDefaultQuantity != null) {
                product.setDefaultQuantity(sanitizedDefaultQuantity);
                changed = true;
            }
        }

        String normalizedBarcode = normalizeBarcode(barcode);
        if (normalizedBarcode != null && !normalizedBarcode.equals(product.getBarcode())) {
            product.setBarcode(normalizedBarcode);
            changed = true;
        }

        if (!changed) {
            return product;
        }

        return catalogProductRepository.save(product);
    }

    public String normalizeBarcode(String barcode) {
        if (barcode == null) {
            return null;
        }

        String normalized = barcode.replaceAll("\\s+", "");
        return normalized.isBlank() ? null : normalized;
    }

    private CatalogProductDetailResponse toDetailResponse(CatalogProduct product) {
        return new CatalogProductDetailResponse(
                product.getId(),
                product.getName(),
                product.getBrand(),
                product.getCategory(),
                product.getDefaultUnit(),
                product.getDefaultQuantity(),
                product.getBarcode()
        );
    }

    private String compactText(String value) {
        return value.trim().replaceAll("\\s+", " ");
    }

    private String sanitizeOptionalText(String value) {
        if (value == null) {
            return null;
        }

        String compacted = value.trim().replaceAll("\\s+", " ");
        return compacted.isBlank() ? null : compacted;
    }

    private Integer sanitizeOptionalInteger(Integer value) {
        if (value == null || value <= 0) {
            return null;
        }
        return value;
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
