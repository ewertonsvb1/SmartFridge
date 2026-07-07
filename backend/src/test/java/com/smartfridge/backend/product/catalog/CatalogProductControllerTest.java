package com.smartfridge.backend.product.catalog;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.lessThanOrEqualTo;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartfridge.backend.auth.dto.LoginRequest;
import com.smartfridge.backend.auth.dto.RegisterRequest;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
class CatalogProductControllerTest {

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
    void shouldDenySearchWithoutToken() throws Exception {
        mockMvc.perform(get("/products/catalog/search").param("q", "lei"))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    assertTrue(status == 401 || status == 403);
                });
    }

    @Test
    void shouldDenyBarcodeLookupWithoutToken() throws Exception {
        mockMvc.perform(get("/products/catalog/barcode/7896004400912"))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    assertTrue(status == 401 || status == 403);
                });
    }

    @Test
    void shouldDenyCatalogDetailWithoutToken() throws Exception {
        mockMvc.perform(get("/products/catalog/1"))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    assertTrue(status == 401 || status == 403);
                });
    }

    @Test
    void shouldRejectSearchTermWithLessThanTwoCharacters() throws Exception {
        String token = registerAndLogin();

        mockMvc.perform(get("/products/catalog/search")
                        .header("Authorization", "Bearer " + token)
                        .param("q", "l"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", is("Search term must have at least 2 characters")));
    }

    @Test
    void shouldReturnSuggestionsIgnoringCaseAndAccentsWithSmartOrdering() throws Exception {
        String token = registerAndLogin();
        saveCatalogProduct("Leite Italac", "leite italac", null);
        saveCatalogProduct("Leite Piracanjuba", "leite piracanjuba", null);
        saveCatalogProduct("Achocolatado com Leite", "achocolatado com leite", null);

        mockMvc.perform(get("/products/catalog/search")
                        .header("Authorization", "Bearer " + token)
                        .param("q", "LEI"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(3)))
                .andExpect(jsonPath("$[0].name", is("Leite Italac")))
                .andExpect(jsonPath("$[1].name", is("Leite Piracanjuba")))
                .andExpect(jsonPath("$[2].name", is("Achocolatado com Leite")))
                .andExpect(jsonPath("$[0].id").isNumber())
                .andExpect(jsonPath("$[0].name").isString());
    }

    @Test
    void shouldLimitSuggestions() throws Exception {
        String token = registerAndLogin();
        for (int index = 1; index <= 12; index++) {
            String name = "Leite Marca " + index;
            saveCatalogProduct(name, "leite marca " + index, null);
        }

        mockMvc.perform(get("/products/catalog/search")
                        .header("Authorization", "Bearer " + token)
                        .param("q", "le"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()", lessThanOrEqualTo(10)));
    }

    @Test
    void shouldReturnCatalogProductByBarcode() throws Exception {
        String token = registerAndLogin();
        saveCatalogProduct("Leite Italac Integral", "leite italac integral", "7896004400912");

        mockMvc.perform(get("/products/catalog/barcode/{barcode}", "78960 04400912")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name", is("Leite Italac Integral")))
                .andExpect(jsonPath("$.id").isNumber());
    }

    @Test
    void shouldReturnNotFoundForUnknownBarcode() throws Exception {
        String token = registerAndLogin();

        mockMvc.perform(get("/products/catalog/barcode/{barcode}", "7896004400912")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message", is("Barcode not found")));
    }

    @Test
    void shouldReturnCatalogProductDetailById() throws Exception {
        String token = registerAndLogin();
        CatalogProduct product = saveCatalogProduct("Leite Italac", "leite italac", "7896004400912");
        product.setBrand("Italac");
        product.setCategory("Laticinios");
        product.setDefaultUnit("L");
        product.setDefaultQuantity(1);
        product = catalogProductRepository.save(product);

        mockMvc.perform(get("/products/catalog/{id}", product.getId())
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(product.getId().intValue())))
                .andExpect(jsonPath("$.name", is("Leite Italac")))
                .andExpect(jsonPath("$.brand", is("Italac")))
                .andExpect(jsonPath("$.category", is("Laticinios")))
                .andExpect(jsonPath("$.defaultUnit", is("L")))
                .andExpect(jsonPath("$.defaultQuantity", is(1)))
                .andExpect(jsonPath("$.barcode", is("7896004400912")));
    }

    private CatalogProduct saveCatalogProduct(String name, String normalizedName, String barcode) {
        CatalogProduct product = new CatalogProduct();
        product.setName(name);
        product.setNormalizedName(normalizedName);
        product.setBarcode(barcode);
        return catalogProductRepository.save(product);
    }

    private String registerAndLogin() throws Exception {
        String email = "catalog_" + UUID.randomUUID() + "@email.com";

        RegisterRequest registerRequest = new RegisterRequest("Catalog User", email, "123456");
        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isOk());

        LoginRequest loginRequest = new LoginRequest(email, "123456");
        MvcResult loginResult = mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode body = objectMapper.readTree(loginResult.getResponse().getContentAsString());
        return body.get("token").asText();
    }
}
