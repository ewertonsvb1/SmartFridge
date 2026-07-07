package com.smartfridge.backend.product.catalog;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.smartfridge.backend.common.exception.BusinessException;
import com.smartfridge.backend.product.catalog.dto.CatalogProductDetailResponse;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class CatalogProductServiceTest {

    @Mock
    private CatalogProductRepository catalogProductRepository;

    private CatalogProductService catalogProductService;

    @BeforeEach
    void setUp() {
        catalogProductService = new CatalogProductService(
                catalogProductRepository,
                new CatalogProductNameNormalizer());
    }

    @Test
    void shouldDelegateFindByNormalizedName() {
        CatalogProduct product = new CatalogProduct();
        product.setNormalizedName("leite italac");
        when(catalogProductRepository.findByNormalizedName("leite italac"))
                .thenReturn(Optional.of(product));

        Optional<CatalogProduct> found = catalogProductService.findByNormalizedName("leite italac");

        assertSame(product, found.orElseThrow());
    }

    @Test
    void shouldCreateCatalogProductWithCompactedNameAndBarcode() {
        CatalogProduct saved = new CatalogProduct();
        saved.setId(1L);
        saved.setName("Leite Italac");
        saved.setNormalizedName("leite italac");
        saved.setBrand("Italac");
        saved.setCategory("Laticinios");
        saved.setDefaultUnit("L");
        saved.setDefaultQuantity(1);
        saved.setBarcode("7896004400912");

        when(catalogProductRepository.save(any(CatalogProduct.class)))
                .thenReturn(saved);

        CatalogProduct result = catalogProductService.create(
                "  Leite   Italac  ",
                "leite italac",
                "  Italac ",
                " Laticinios ",
                "  L ",
                1,
                "78960 04400912");

        assertEquals(1L, result.getId());
        verify(catalogProductRepository).save(org.mockito.ArgumentMatchers.argThat(product ->
                product.getName().equals("Leite Italac")
                        && product.getNormalizedName().equals("leite italac")
                        && product.getBrand().equals("Italac")
                        && product.getCategory().equals("Laticinios")
                        && product.getDefaultUnit().equals("L")
                        && product.getDefaultQuantity().equals(1)
                        && product.getBarcode().equals("7896004400912")));
    }

    @Test
    void shouldFillOnlyMissingCatalogFieldsWhenEnriching() {
        CatalogProduct existing = new CatalogProduct();
        existing.setName("Leite Italac");
        existing.setNormalizedName("leite italac");
        existing.setBrand("Italac");
        existing.setCategory(null);
        existing.setDefaultUnit("");
        existing.setDefaultQuantity(null);
        existing.setBarcode(null);

        when(catalogProductRepository.save(any(CatalogProduct.class))).thenAnswer(invocation -> invocation.getArgument(0));

        CatalogProduct result = catalogProductService.enrichIfMissing(
                existing,
                "Outra Marca",
                "Laticinios",
                "L",
                2,
                "78960 04400912");

        assertSame(existing, result);
        assertEquals("Italac", result.getBrand());
        assertEquals("Laticinios", result.getCategory());
        assertEquals("L", result.getDefaultUnit());
        assertEquals(2, result.getDefaultQuantity());
        assertEquals("7896004400912", result.getBarcode());
    }

    @Test
    void shouldIgnoreBlankAndInvalidValuesWhenEnriching() {
        CatalogProduct existing = new CatalogProduct();
        existing.setName("Leite Italac");
        existing.setNormalizedName("leite italac");

        CatalogProduct result = catalogProductService.enrichIfMissing(
                existing,
                "   ",
                null,
                " ",
                0,
                "   ");

        assertSame(existing, result);
        assertNull(result.getBrand());
        assertNull(result.getCategory());
        assertNull(result.getDefaultUnit());
        assertNull(result.getDefaultQuantity());
        assertNull(result.getBarcode());
    }

    @Test
    void shouldReturnCatalogDetailById() {
        CatalogProduct product = new CatalogProduct();
        product.setId(7L);
        product.setName("Leite Italac");
        product.setNormalizedName("leite italac");
        product.setBrand("Italac");
        product.setCategory("Laticinios");
        product.setDefaultUnit("L");
        product.setDefaultQuantity(1);
        product.setBarcode("7896004400912");
        when(catalogProductRepository.findById(7L)).thenReturn(Optional.of(product));

        CatalogProductDetailResponse response = catalogProductService.findDetailById(7L);

        assertEquals(7L, response.id());
        assertEquals("Leite Italac", response.name());
        assertEquals("Italac", response.brand());
        assertEquals("Laticinios", response.category());
        assertEquals("L", response.defaultUnit());
        assertEquals(1, response.defaultQuantity());
        assertEquals("7896004400912", response.barcode());
    }

    @Test
    void shouldRejectSearchWithLessThanTwoCharacters() {
        assertThrows(BusinessException.class, () -> catalogProductService.searchSuggestions("l"));
    }

    @Test
    void shouldNormalizeBarcodeBeforeFinding() {
        CatalogProduct product = new CatalogProduct();
        product.setBarcode("7896004400912");
        when(catalogProductRepository.findByBarcode("7896004400912"))
                .thenReturn(Optional.of(product));

        Optional<CatalogProduct> found = catalogProductService.findByBarcode("78960 04400912");

        assertSame(product, found.orElseThrow());
    }
}
