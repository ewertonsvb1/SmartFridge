package com.smartfridge.backend.product;

import java.time.LocalDate;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ProductServiceTest {

    private final ProductService productService = new ProductService(
            null,
            null,
            null,
            null
    );

    @Test
    void shouldReturnExpiredWhenDateIsInPast() {
        ProductStatus status = productService.calculateStatus(LocalDate.now().minusDays(1));
        assertEquals(ProductStatus.EXPIRED, status);
    }

    @Test
    void shouldReturnNearExpirationWhenDateIsWithinThreeDays() {
        ProductStatus status = productService.calculateStatus(LocalDate.now().plusDays(2));
        assertEquals(ProductStatus.NEAR_EXPIRATION, status);
    }

    @Test
    void shouldReturnOkWhenDateIsBeyondThreeDays() {
        ProductStatus status = productService.calculateStatus(LocalDate.now().plusDays(10));
        assertEquals(ProductStatus.OK, status);
    }
}
