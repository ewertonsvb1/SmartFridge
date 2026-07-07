package com.smartfridge.backend.product.catalog;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.smartfridge.backend.common.exception.BusinessException;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

@ExtendWith(MockitoExtension.class)
class CatalogSyncServiceTest {

    @Mock
    private CatalogProductRepository catalogProductRepository;

    private CatalogSyncService catalogSyncService;

    @BeforeEach
    void setUp() {
        CatalogProductService catalogProductService = new CatalogProductService(
                catalogProductRepository,
                new CatalogProductNameNormalizer());
        catalogSyncService = new CatalogSyncService(
                catalogProductService,
                new CatalogProductNameNormalizer());
    }

    @Test
    void shouldCreateCatalogProductWhenNormalizedNameDoesNotExist() {
        CatalogProduct created = new CatalogProduct();
        created.setId(1L);
        created.setName("Leite Italac");
        created.setNormalizedName("leite italac");

        when(catalogProductRepository.findByNormalizedName("leite italac")).thenReturn(Optional.empty());
        when(catalogProductRepository.save(any(CatalogProduct.class))).thenReturn(created);

        CatalogProduct result = catalogSyncService.ensureExists("  Leite   Italac  ");

        assertSame(created, result);
    }

    @Test
    void shouldReuseExistingCatalogProductWhenNormalizedNameAlreadyExists() {
        CatalogProduct existing = new CatalogProduct();
        existing.setId(2L);
        existing.setName("Leite Italac");
        existing.setNormalizedName("leite italac");

        when(catalogProductRepository.findByNormalizedName("leite italac")).thenReturn(Optional.of(existing));

        CatalogProduct result = catalogSyncService.ensureExists("LEITE ITALAC");

        assertSame(existing, result);
        verify(catalogProductRepository, never()).save(any(CatalogProduct.class));
    }

    @Test
    void shouldReturnExistingCatalogProductWhenConcurrentInsertTriggersUniqueViolation() {
        CatalogProduct existing = new CatalogProduct();
        existing.setId(3L);
        existing.setName("Leite Italac");
        existing.setNormalizedName("leite italac");

        when(catalogProductRepository.findByNormalizedName("leite italac"))
                .thenReturn(Optional.empty())
                .thenReturn(Optional.of(existing));
        when(catalogProductRepository.save(any(CatalogProduct.class)))
                .thenThrow(new DataIntegrityViolationException("duplicate"));

        CatalogProduct result = catalogSyncService.ensureExists("Leite Italac");

        assertSame(existing, result);
    }

    @Test
    void shouldNormalizeBeforeSyncing() {
        CatalogProduct existing = new CatalogProduct();
        existing.setId(4L);
        existing.setName("Leite Italac");
        existing.setNormalizedName("leite italac");

        when(catalogProductRepository.findByNormalizedName("leite italac")).thenReturn(Optional.of(existing));

        CatalogProduct result = catalogSyncService.ensureExists("  Leite   ITALAC ");

        assertEquals("leite italac", result.getNormalizedName());
    }

    @Test
    void shouldAssignBarcodeToExistingCatalogProductWithoutBarcode() {
        CatalogProduct existing = new CatalogProduct();
        existing.setId(5L);
        existing.setName("Leite Italac");
        existing.setNormalizedName("leite italac");

        when(catalogProductRepository.findByBarcode("7896004400912")).thenReturn(Optional.empty());
        when(catalogProductRepository.findByNormalizedName("leite italac")).thenReturn(Optional.of(existing));
        when(catalogProductRepository.save(any(CatalogProduct.class))).thenAnswer(invocation -> {
            CatalogProduct saved = invocation.getArgument(0, CatalogProduct.class);
            existing.setBarcode(saved.getBarcode());
            return existing;
        });

        CatalogProduct result = catalogSyncService.ensureExists("Leite Italac", "78960 04400912");

        assertEquals("7896004400912", result.getBarcode());
    }

    @Test
    void shouldRejectBarcodeAssociatedWithAnotherProduct() {
        CatalogProduct existing = new CatalogProduct();
        existing.setId(6L);
        existing.setName("Arroz");
        existing.setNormalizedName("arroz");
        existing.setBarcode("7896004400912");

        when(catalogProductRepository.findByBarcode("7896004400912")).thenReturn(Optional.of(existing));

        assertThrows(BusinessException.class,
                () -> catalogSyncService.ensureExists("Leite Italac", "7896004400912"));
    }

    @Test
    void shouldEnrichOnlyMissingFieldsOnExistingCatalogProduct() {
        CatalogProduct existing = new CatalogProduct();
        existing.setId(7L);
        existing.setName("Leite Italac");
        existing.setNormalizedName("leite italac");

        when(catalogProductRepository.findByBarcode("7896004400912")).thenReturn(Optional.empty());
        when(catalogProductRepository.findByNormalizedName("leite italac")).thenReturn(Optional.of(existing));
        when(catalogProductRepository.save(any(CatalogProduct.class))).thenAnswer(invocation -> invocation.getArgument(0));

        CatalogProduct result = catalogSyncService.ensureExists(
                "Leite Italac",
                "Italac",
                "Laticinios",
                "L",
                1,
                "7896004400912");

        assertSame(existing, result);
        assertEquals("Italac", result.getBrand());
        assertEquals("Laticinios", result.getCategory());
        assertEquals("L", result.getDefaultUnit());
        assertEquals(1, result.getDefaultQuantity());
        assertEquals("7896004400912", result.getBarcode());
    }
}
