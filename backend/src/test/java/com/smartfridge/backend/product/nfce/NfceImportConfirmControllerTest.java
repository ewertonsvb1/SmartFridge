package com.smartfridge.backend.product.nfce;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartfridge.backend.auth.dto.LoginRequest;
import com.smartfridge.backend.auth.dto.RegisterRequest;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.is;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class NfceImportConfirmControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void shouldDenyConfirmWithoutToken() throws Exception {
        mockMvc.perform(post("/products/nfce/confirm")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "items": [
                                    {
                                      "name": "Leite",
                                      "quantity": 1,
                                      "manufactureDate": "2026-06-15",
                                      "expirationDate": "2026-06-22"
                                    }
                                  ]
                                }
                                """))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    assertTrue(status == 401 || status == 403);
                });
    }

    @Test
    void shouldConfirmImportedProductsAndCreateNotifications() throws Exception {
        String token = registerAndLogin();
        LocalDate today = LocalDate.now();

        mockMvc.perform(post("/products/nfce/confirm")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "items": [
                                    {
                                      "name": "Leite Integral",
                                      "quantity": 2,
                                      "manufactureDate": "%s",
                                      "expirationDate": "%s"
                                    },
                                    {
                                      "name": "Queijo Minas",
                                      "quantity": 1,
                                      "manufactureDate": "%s",
                                      "expirationDate": "%s"
                                    }
                                  ]
                                }
                                """.formatted(today, today.plusDays(2), today.minusDays(10), today.minusDays(1))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.createdCount", is(2)))
                .andExpect(jsonPath("$.products", hasSize(2)))
                .andExpect(jsonPath("$.products[0].status", is("NEAR_EXPIRATION")))
                .andExpect(jsonPath("$.products[1].status", is("EXPIRED")));

        mockMvc.perform(get("/products")
                        .header("Authorization", "Bearer " + token)
                        .param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(2)));

        mockMvc.perform(get("/notifications")
                        .header("Authorization", "Bearer " + token)
                        .param("limit", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].sourceModule", is("PRODUCT")))
                .andExpect(jsonPath("$[1].sourceModule", is("PRODUCT")));
    }

    @Test
    void shouldFailWholeBatchWhenAnyImportedItemIsInvalid() throws Exception {
        String token = registerAndLogin();
        LocalDate today = LocalDate.now();

        mockMvc.perform(post("/products/nfce/confirm")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "items": [
                                    {
                                      "name": "Leite Integral",
                                      "quantity": 2,
                                      "manufactureDate": "%s",
                                      "expirationDate": "%s"
                                    },
                                    {
                                      "name": "Iogurte Natural",
                                      "quantity": 1,
                                      "manufactureDate": "%s",
                                      "expirationDate": "%s"
                                    }
                                  ]
                                }
                                """.formatted(today, today.plusDays(2), today, today.minusDays(3))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", is("Expiration date cannot be before manufacture date")));

        mockMvc.perform(get("/products")
                        .header("Authorization", "Bearer " + token)
                        .param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(0)));
    }

    private String registerAndLogin() throws Exception {
        String email = "nfce_confirm_" + UUID.randomUUID() + "@email.com";

        RegisterRequest registerRequest = new RegisterRequest("NFCE Confirm User", email, "123456");
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
