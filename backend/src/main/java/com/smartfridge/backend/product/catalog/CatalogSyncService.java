package com.smartfridge.backend.product.catalog;

import com.smartfridge.backend.common.exception.BusinessException;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CatalogSyncService {

    private final CatalogProductService catalogProductService;
    private final CatalogProductNameNormalizer catalogProductNameNormalizer;

    @Transactional
    public CatalogProduct ensureExists(String productName) {
        return ensureExists(productName, null, null, null, null, null);
    }

    @Transactional
    public CatalogProduct ensureExists(String productName, String barcode) {
        return ensureExists(productName, null, null, null, null, barcode);
    }

    @Transactional
    public CatalogProduct ensureExists(
            String productName,
            String brand,
            String category,
            String defaultUnit,
            Integer defaultQuantity,
            String barcode
    ) {
        String normalizedName = catalogProductNameNormalizer.normalize(productName);
        String normalizedBarcode = catalogProductService.normalizeBarcode(barcode);

        if (normalizedBarcode != null) {
            Optional<CatalogProduct> existingByBarcode = catalogProductService.findByBarcode(normalizedBarcode);
            if (existingByBarcode.isPresent()) {
                CatalogProduct product = existingByBarcode.get();
                if (!product.getNormalizedName().equals(normalizedName)) {
                    throw new BusinessException("Barcode already associated with another product");
                }
                return product;
            }
        }

        Optional<CatalogProduct> existing = catalogProductService.findByNormalizedName(normalizedName);
        if (existing.isPresent()) {
            CatalogProduct product = existing.get();
            if (normalizedBarcode != null
                    && product.getBarcode() != null
                    && !normalizedBarcode.equals(product.getBarcode())) {
                throw new BusinessException("Product already associated with another barcode");
            }
            return catalogProductService.enrichIfMissing(
                    product,
                    brand,
                    category,
                    defaultUnit,
                    defaultQuantity,
                    normalizedBarcode);
        }

        try {
            return catalogProductService.create(
                    productName,
                    normalizedName,
                    brand,
                    category,
                    defaultUnit,
                    defaultQuantity,
                    normalizedBarcode);
        } catch (DataIntegrityViolationException exception) {
            if (normalizedBarcode != null) {
                Optional<CatalogProduct> existingByBarcode = catalogProductService.findByBarcode(normalizedBarcode);
                if (existingByBarcode.isPresent()) {
                    CatalogProduct product = existingByBarcode.get();
                    if (!product.getNormalizedName().equals(normalizedName)) {
                        throw new BusinessException("Barcode already associated with another product");
                    }
                    return product;
                }
            }

            return catalogProductService.findByNormalizedName(normalizedName)
                    .map(product -> {
                        if (normalizedBarcode != null
                                && product.getBarcode() != null
                                && !normalizedBarcode.equals(product.getBarcode())) {
                            throw new BusinessException("Product already associated with another barcode");
                        }
                        return catalogProductService.enrichIfMissing(
                                product,
                                brand,
                                category,
                                defaultUnit,
                                defaultQuantity,
                                normalizedBarcode);
                    })
                    .orElseThrow(() -> exception);
        }
    }
}
