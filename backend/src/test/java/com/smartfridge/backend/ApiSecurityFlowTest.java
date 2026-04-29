package com.smartfridge.backend;

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
import org.springframework.test.web.servlet.MvcResult;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class ApiSecurityFlowTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void shouldDenyProtectedEndpointsWithoutToken() throws Exception {
        mockMvc.perform(get("/products"))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    assertTrue(status == 401 || status == 403);
                });

        mockMvc.perform(get("/shopping-list"))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    assertTrue(status == 401 || status == 403);
                });
    }

    @Test
    void shouldExecuteProductAndShoppingCrudWithAuthenticatedUser() throws Exception {
        String token = registerAndLogin();

        LocalDate today = LocalDate.now();
        LocalDate expiration = today.plusDays(5);

        MvcResult createdProductResult = mockMvc.perform(post("/products")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Leite Integral",
                                  "quantity": 2,
                                  "manufactureDate": "%s",
                                  "expirationDate": "%s"
                                }
                                """.formatted(today, expiration)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.name").value("Leite Integral"))
                .andReturn();

        long productId = readLong(createdProductResult, "id");

        mockMvc.perform(put("/products/{id}", productId)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Leite Desnatado",
                                  "quantity": 3,
                                  "manufactureDate": "%s",
                                  "expirationDate": "%s"
                                }
                                """.formatted(today, expiration.plusDays(2))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Leite Desnatado"))
                .andExpect(jsonPath("$.quantity").value(3));

        mockMvc.perform(get("/products")
                        .header("Authorization", "Bearer " + token)
                        .param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isArray());

        MvcResult createdShoppingResult = mockMvc.perform(post("/shopping-list")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Ovos",
                                  "quantity": 12
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.name").value("Ovos"))
                .andReturn();

        long shoppingId = readLong(createdShoppingResult, "id");

        mockMvc.perform(put("/shopping-list/{id}", shoppingId)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Ovos Caipira",
                                  "quantity": 10,
                                  "checked": true
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Ovos Caipira"))
                .andExpect(jsonPath("$.quantity").value(10))
                .andExpect(jsonPath("$.checked").value(true));

        mockMvc.perform(get("/shopping-list")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").isNumber());

        mockMvc.perform(delete("/shopping-list/{id}", shoppingId)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isNoContent());

        mockMvc.perform(delete("/products/{id}", productId)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isNoContent());
    }

    private String registerAndLogin() throws Exception {
        String email = "flow_" + UUID.randomUUID() + "@email.com";

        RegisterRequest registerRequest = new RegisterRequest("Flow User", email, "123456");
        mockMvc.perform(post("/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty());

        LoginRequest loginRequest = new LoginRequest(email, "123456");
        MvcResult loginResult = mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andReturn();

        JsonNode body = objectMapper.readTree(loginResult.getResponse().getContentAsString());
        return body.get("token").asText();
    }

    private long readLong(MvcResult result, String field) throws Exception {
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        return body.get(field).asLong();
    }
}
