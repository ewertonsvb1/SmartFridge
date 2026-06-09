package com.smartfridge.backend.housebill;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartfridge.backend.auth.dto.LoginRequest;
import com.smartfridge.backend.auth.dto.RegisterRequest;
import java.math.BigDecimal;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class HouseBillControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void shouldDenyHouseBillsWithoutToken() throws Exception {
        mockMvc.perform(get("/house-bills"))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    assertTrue(status == 401 || status == 403);
                });
    }

    @Test
    void shouldExecuteHouseBillsCrudPaymentAndDashboardFlow() throws Exception {
        String token = registerAndLogin();
        LocalDate today = LocalDate.now();

        long openBillId = createBill(token, "Internet", new BigDecimal("120.50"), today.plusDays(10), "Casa");
        long overdueBillId = createBill(token, "Agua", new BigDecimal("45.10"), today.minusDays(2), "Casa");
        long paidBillId = createBill(token, "Energia", new BigDecimal("80.00"), today.plusDays(2), "Moradia");

        mockMvc.perform(get("/house-bills")
                        .header("Authorization", "Bearer " + token)
                        .param("status", "OPEN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2));

        mockMvc.perform(get("/house-bills")
                        .header("Authorization", "Bearer " + token)
                        .param("status", "OVERDUE"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(overdueBillId));

        mockMvc.perform(get("/house-bills")
                        .header("Authorization", "Bearer " + token)
                        .param("startDate", today.minusDays(3).toString())
                        .param("endDate", today.plusDays(3).toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2));

        mockMvc.perform(put("/house-bills/{id}", openBillId)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "description": "Internet residencial",
                                  "amount": 130.75,
                                  "dueDate": "%s",
                                  "category": "Conectividade"
                                }
                                """.formatted(today.plusDays(12))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.description").value("Internet residencial"))
                .andExpect(jsonPath("$.amount").value(130.75));

        mockMvc.perform(patch("/house-bills/{id}/payment", paidBillId)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("PAID"))
                .andExpect(jsonPath("$.paidAt").isNotEmpty());

        mockMvc.perform(get("/house-bills/{id}", paidBillId)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("PAID"));

        mockMvc.perform(get("/house-bills/dashboard")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalCount").value(3))
                .andExpect(jsonPath("$.openCount").value(1))
                .andExpect(jsonPath("$.overdueCount").value(1))
                .andExpect(jsonPath("$.paidCount").value(1))
                .andExpect(jsonPath("$.totalAmount").value(255.85))
                .andExpect(jsonPath("$.openAmount").value(130.75))
                .andExpect(jsonPath("$.paidAmount").value(80.00))
                .andExpect(jsonPath("$.overdueAmount").value(45.10));

        mockMvc.perform(delete("/house-bills/{id}", overdueBillId)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/house-bills")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    void shouldRestrictHouseBillsToAuthenticatedUser() throws Exception {
        String tokenA = registerAndLogin();
        String tokenB = registerAndLogin();
        LocalDate today = LocalDate.now();

        long billA = createBill(tokenA, "Internet A", new BigDecimal("99.90"), today.plusDays(5), "Casa");
        createBill(tokenB, "Internet B", new BigDecimal("88.00"), today.plusDays(6), "Casa");

        mockMvc.perform(get("/house-bills")
                        .header("Authorization", "Bearer " + tokenA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].id").value(billA));

        mockMvc.perform(get("/house-bills/{id}", billA)
                        .header("Authorization", "Bearer " + tokenB))
                .andExpect(status().isNotFound());
    }

    @Test
    void shouldRejectInvalidHouseBillInputsAndRanges() throws Exception {
        String token = registerAndLogin();
        LocalDate today = LocalDate.now();

        mockMvc.perform(post("/house-bills")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "description": "Conta invalida",
                                  "amount": 0,
                                  "dueDate": "%s",
                                  "category": "Casa"
                                }
                                """.formatted(today.plusDays(1))))
                .andExpect(status().isBadRequest());

        mockMvc.perform(get("/house-bills")
                        .header("Authorization", "Bearer " + token)
                        .param("startDate", today.plusDays(2).toString())
                        .param("endDate", today.toString()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("End date cannot be before start date"));
    }

    private long createBill(
            String token,
            String description,
            BigDecimal amount,
            LocalDate dueDate,
            String category
    ) throws Exception {
        MvcResult result = mockMvc.perform(post("/house-bills")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "description": "%s",
                                  "amount": %s,
                                  "dueDate": "%s",
                                  "category": "%s"
                                }
                                """.formatted(description, amount.toPlainString(), dueDate, category)))
                .andExpect(status().isCreated())
                .andReturn();

        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        return body.get("id").asLong();
    }

    private String registerAndLogin() throws Exception {
        String email = "housebill_" + UUID.randomUUID() + "@email.com";

        RegisterRequest registerRequest = new RegisterRequest("House Bill User", email, "123456");
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
