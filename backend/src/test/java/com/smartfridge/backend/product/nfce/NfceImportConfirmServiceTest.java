package com.smartfridge.backend.product.nfce;

import com.smartfridge.backend.product.ProductMapper;
import com.smartfridge.backend.product.ProductService;
import com.smartfridge.backend.product.ProductStatus;
import com.smartfridge.backend.product.nfce.dto.NfceImportConfirmItemRequest;
import com.smartfridge.backend.product.nfce.dto.NfceImportConfirmRequest;
import com.smartfridge.backend.user.UserEntity;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NfceImportConfirmServiceTest {

    @Mock
    private ProductService productService;

    private NfceImportConfirmService nfceImportConfirmService;

    @org.junit.jupiter.api.BeforeEach
    void setUp() {
        nfceImportConfirmService = new NfceImportConfirmService(productService, new ProductMapper());
    }

    @Test
    void shouldReuseProductCreationForEachImportedItem() {
        LocalDate manufactureDate = LocalDate.of(2026, 6, 15);
        LocalDate expirationDate = LocalDate.of(2026, 6, 22);

        when(productService.create(org.mockito.ArgumentMatchers.any())).thenReturn(productEntity(
                1L,
                "Leite Integral",
                2,
                manufactureDate,
                expirationDate,
                ProductStatus.OK
        ));

        var request = new NfceImportConfirmRequest(List.of(
                new NfceImportConfirmItemRequest("Leite Integral", 2, manufactureDate, expirationDate)
        ));

        var response = nfceImportConfirmService.confirm(request);

        ArgumentCaptor<com.smartfridge.backend.product.dto.ProductCreateRequest> captor =
                ArgumentCaptor.forClass(com.smartfridge.backend.product.dto.ProductCreateRequest.class);
        verify(productService, times(1)).create(captor.capture());
        assertEquals("Leite Integral", captor.getValue().name());
        assertEquals(1, response.createdCount());
        assertEquals("Leite Integral", response.products().getFirst().name());
    }

    private com.smartfridge.backend.product.ProductEntity productEntity(
            Long id,
            String name,
            Integer quantity,
            LocalDate manufactureDate,
            LocalDate expirationDate,
            ProductStatus status
    ) {
        UserEntity user = new UserEntity();
        user.setId(99L);

        com.smartfridge.backend.product.ProductEntity entity = new com.smartfridge.backend.product.ProductEntity();
        entity.setId(id);
        entity.setName(name);
        entity.setQuantity(quantity);
        entity.setManufactureDate(manufactureDate);
        entity.setExpirationDate(expirationDate);
        entity.setStatus(status);
        entity.setUser(user);
        entity.setCreatedAt(Instant.parse("2026-06-15T12:00:00Z"));
        return entity;
    }
}
