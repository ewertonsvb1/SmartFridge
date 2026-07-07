package com.smartfridge.backend.product.catalog;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartfridge.backend.auth.dto.LoginRequest;
import com.smartfridge.backend.auth.dto.RegisterRequest;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class ProductCatalogSyncIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private CatalogProductRepository catalogProductRepository;

    @BeforeEach
    void setUp() {
        catalogProductRepository.deleteAll();
    }

    @Test
    void shouldCreateCatalogEntryWhenCreatingProduct() throws Exception {
        String token = registerAndLogin();
        LocalDate today = LocalDate.now();

        createProduct(token, "Leite Italac", today, today.plusDays(5), null, null, null, null, null);

        assertThat(catalogProductRepository.count()).isEqualTo(1);
        CatalogProduct catalogProduct = catalogProductRepository.findAll().getFirst();
        assertThat(catalogProduct.getName()).isEqualTo("Leite Italac");
        assertThat(catalogProduct.getNormalizedName()).isEqualTo("leite italac");
    }

    @Test
    void shouldReuseExistingCatalogEntryWhenCreatingSemanticDuplicateProduct() throws Exception {
        String token = registerAndLogin();
        LocalDate today = LocalDate.now();

        createProduct(token, "Leite Italac", today, today.plusDays(5), null, null, null, null, null);
        createProduct(token, "  Leite   ITALAC  ", today, today.plusDays(8), null, null, null, null, null);

        assertThat(catalogProductRepository.count()).isEqualTo(1);
        CatalogProduct catalogProduct = catalogProductRepository.findAll().getFirst();
        assertThat(catalogProduct.getNormalizedName()).isEqualTo("leite italac");
    }

    @Test
    void shouldAssociateBarcodeWhenCreatingProduct() throws Exception {
        String token = registerAndLogin();
        LocalDate today = LocalDate.now();

        createProduct(token, "Leite Italac", today, today.plusDays(5), "7896004400912", null, null, null, null);

        CatalogProduct catalogProduct = catalogProductRepository.findAll().getFirst();
        assertThat(catalogProduct.getBarcode()).isEqualTo("7896004400912");
    }

    @Test
    void shouldReuseExistingCatalogProductAndAssignBarcode() throws Exception {
        String token = registerAndLogin();
        LocalDate today = LocalDate.now();

        createProduct(token, "Leite Italac", today, today.plusDays(5), null, null, null, null, null);
        createProduct(token, "Leite Italac", today, today.plusDays(8), "7896004400912", null, null, null, null);

        assertThat(catalogProductRepository.count()).isEqualTo(1);
        CatalogProduct catalogProduct = catalogProductRepository.findAll().getFirst();
        assertThat(catalogProduct.getBarcode()).isEqualTo("7896004400912");
    }

    @Test
    void shouldCreateCatalogEntryWithOptionalMetadata() throws Exception {
        String token = registerAndLogin();
        LocalDate today = LocalDate.now();

        createProduct(
                token,
                "Leite Italac",
                today,
                today.plusDays(5),
                "7896004400912",
                "Italac",
                "Laticinios",
                "L",
                1);

        CatalogProduct catalogProduct = catalogProductRepository.findAll().getFirst();
        assertThat(catalogProduct.getBrand()).isEqualTo("Italac");
        assertThat(catalogProduct.getCategory()).isEqualTo("Laticinios");
        assertThat(catalogProduct.getDefaultUnit()).isEqualTo("L");
        assertThat(catalogProduct.getDefaultQuantity()).isEqualTo(1);
    }

    @Test
    void shouldEnrichOnlyMissingCatalogFieldsWithoutOverwritingExistingValues() throws Exception {
        String token = registerAndLogin();
        LocalDate today = LocalDate.now();

        createProduct(
                token,
                "Leite Italac",
                today,
                today.plusDays(5),
                null,
                "Italac",
                null,
                null,
                null);
        createProduct(
                token,
                "Leite Italac",
                today,
                today.plusDays(8),
                "7896004400912",
                "Outra Marca",
                "Laticinios",
                "L",
                2);

        CatalogProduct catalogProduct = catalogProductRepository.findAll().getFirst();
        assertThat(catalogProduct.getBrand()).isEqualTo("Italac");
        assertThat(catalogProduct.getCategory()).isEqualTo("Laticinios");
        assertThat(catalogProduct.getDefaultUnit()).isEqualTo("L");
        assertThat(catalogProduct.getDefaultQuantity()).isEqualTo(2);
        assertThat(catalogProduct.getBarcode()).isEqualTo("7896004400912");
    }

    @Test
    void shouldRejectDuplicateBarcodeForDifferentCatalogProducts() throws Exception {
        String token = registerAndLogin();
        LocalDate today = LocalDate.now();

        createProduct(token, "Leite Italac", today, today.plusDays(5), "7896004400912", null, null, null, null);

        mockMvc.perform(post("/products")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Arroz Branco",
                                  "quantity": 2,
                                  "manufactureDate": "%s",
                                  "expirationDate": "%s",
                                  "barcode": "7896004400912"
                                }
                                """.formatted(today, today.plusDays(10))))
                .andExpect(status().isBadRequest());
    }

    private void createProduct(
            String token,
            String name,
            LocalDate manufactureDate,
            LocalDate expirationDate,
            String barcode,
            String brand,
            String category,
            String defaultUnit,
            Integer defaultQuantity
    ) throws Exception {
        mockMvc.perform(post("/products")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "%s",
                                  "quantity": 2,
                                  "manufactureDate": "%s",
                                  "expirationDate": "%s",
                                  "brand": %s,
                                  "category": %s,
                                  "defaultUnit": %s,
                                  "defaultQuantity": %s,
                                  "barcode": %s
                                }
                                """.formatted(
                                name,
                                manufactureDate,
                                expirationDate,
                                toJsonValue(brand),
                                toJsonValue(category),
                                toJsonValue(defaultUnit),
                                defaultQuantity == null ? "null" : defaultQuantity,
                                barcode == null ? "null" : "\"%s\"".formatted(barcode))))
                .andExpect(status().isCreated());
    }

    private String toJsonValue(String value) {
        return value == null ? "null" : "\"%s\"".formatted(value);
    }

    private String registerAndLogin() throws Exception {
        String email = "product_catalog_" + UUID.randomUUID() + "@email.com";

        RegisterRequest registerRequest = new RegisterRequest("Catalog Product User", email, "123456");
        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isOk());

        LoginRequest loginRequest = new LoginRequest(email, "123456");
        String body = mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode jsonNode = objectMapper.readTree(body);
        return jsonNode.get("token").asText();
    }
}
