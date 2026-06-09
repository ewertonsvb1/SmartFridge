package com.smartfridge.backend.dashboard;

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

import static org.hamcrest.Matchers.is;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class DashboardControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void shouldDenyDashboardWithoutToken() throws Exception {
        mockMvc.perform(get("/dashboard"))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    assertTrue(status == 401 || status == 403);
                });
    }

    @Test
    void shouldReturnGlobalDashboardWithModuleCounts() throws Exception {
        String token = registerAndLogin();
        LocalDate today = LocalDate.now();

        createProduct(token, "Leite", 2, today, today.plusDays(5));
        createProduct(token, "Iogurte", 1, today.minusDays(2), today.minusDays(1));
        createProduct(token, "Queijo", 1, today, today.plusDays(2));
        createEvent(token, "Consulta", today + "T09:00:00", today + "T10:00:00", "SCHEDULED");
        createEvent(
                token,
                "Passeio",
                today.plusDays(2) + "T14:00:00",
                today.plusDays(2) + "T15:00:00",
                "SCHEDULED"
        );
        createEvent(
                token,
                "Evento passado",
                today.minusDays(1) + "T08:00:00",
                today.minusDays(1) + "T09:00:00",
                "COMPLETED"
        );
        createBill(token, "Internet", new BigDecimal("100.00"), today.plusDays(5), "Casa");
        createBill(token, "Agua", new BigDecimal("55.00"), today.minusDays(1), "Casa");
        long paidBillId = createBill(token, "Energia", new BigDecimal("80.00"), today.plusDays(1), "Casa");
        markBillAsPaid(token, paidBillId);

        mockMvc.perform(get("/dashboard")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fridge.total").value(3))
                .andExpect(jsonPath("$.fridge.expired").value(1))
                .andExpect(jsonPath("$.fridge.nearExpiration").value(1))
                .andExpect(jsonPath("$.agenda.implemented", is(true)))
                .andExpect(jsonPath("$.agenda.total").value(3))
                .andExpect(jsonPath("$.agenda.today").value(1))
                .andExpect(jsonPath("$.agenda.upcoming").value(1))
                .andExpect(jsonPath("$.houseBills.implemented", is(true)))
                .andExpect(jsonPath("$.houseBills.totalOpen").value(1))
                .andExpect(jsonPath("$.houseBills.overdue").value(1))
                .andExpect(jsonPath("$.houseBills.paid").value(1));
    }

    @Test
    void shouldRestrictDashboardCountsToAuthenticatedUser() throws Exception {
        String tokenA = registerAndLogin();
        String tokenB = registerAndLogin();
        LocalDate today = LocalDate.now();

        createProduct(tokenA, "Leite A", 1, today, today.plusDays(1));
        createProduct(tokenA, "Iogurte A", 1, today.minusDays(2), today.minusDays(1));
        createProduct(tokenB, "Leite B", 1, today, today.plusDays(10));
        createEvent(tokenA, "Evento A", today + "T08:00:00", today + "T09:00:00", "SCHEDULED");
        createEvent(tokenB, "Evento B", today.plusDays(1) + "T08:00:00", today.plusDays(1) + "T09:00:00", "SCHEDULED");
        createBill(tokenA, "Conta A", new BigDecimal("30.00"), today.plusDays(2), "Casa");
        createBill(tokenB, "Conta B", new BigDecimal("40.00"), today.minusDays(1), "Casa");

        mockMvc.perform(get("/dashboard")
                        .header("Authorization", "Bearer " + tokenA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fridge.total").value(2))
                .andExpect(jsonPath("$.fridge.expired").value(1))
                .andExpect(jsonPath("$.fridge.nearExpiration").value(1))
                .andExpect(jsonPath("$.agenda.total").value(1))
                .andExpect(jsonPath("$.houseBills.totalOpen").value(1))
                .andExpect(jsonPath("$.houseBills.overdue").value(0));

        mockMvc.perform(get("/dashboard")
                        .header("Authorization", "Bearer " + tokenB))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fridge.total").value(1))
                .andExpect(jsonPath("$.fridge.expired").value(0))
                .andExpect(jsonPath("$.fridge.nearExpiration").value(0))
                .andExpect(jsonPath("$.agenda.total").value(1))
                .andExpect(jsonPath("$.houseBills.totalOpen").value(0))
                .andExpect(jsonPath("$.houseBills.overdue").value(1));
    }

    private void createProduct(
            String token,
            String name,
            int quantity,
            LocalDate manufactureDate,
            LocalDate expirationDate
    ) throws Exception {
        mockMvc.perform(post("/products")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "%s",
                                  "quantity": %d,
                                  "manufactureDate": "%s",
                                  "expirationDate": "%s"
                                }
                                """.formatted(name, quantity, manufactureDate, expirationDate)))
                .andExpect(status().isCreated());
    }

    private void createEvent(String token, String title, String startAt, String endAt, String statusValue) throws Exception {
        mockMvc.perform(post("/agenda/events")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "%s",
                                  "description": "Teste",
                                  "startAt": "%s",
                                  "endAt": "%s",
                                  "status": "%s"
                                }
                                """.formatted(title, startAt, endAt, statusValue)))
                .andExpect(status().isCreated());
    }

    private long createBill(
            String token,
            String description,
            BigDecimal amount,
            LocalDate dueDate,
            String category
    ) throws Exception {
        String body = mockMvc.perform(post("/house-bills")
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
                .andReturn()
                .getResponse()
                .getContentAsString();

        return objectMapper.readTree(body).get("id").asLong();
    }

    private void markBillAsPaid(String token, long billId) throws Exception {
        mockMvc.perform(patch("/house-bills/{id}/payment", billId)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk());
    }

    private String registerAndLogin() throws Exception {
        String email = "dashboard_" + UUID.randomUUID() + "@email.com";

        RegisterRequest registerRequest = new RegisterRequest("Dashboard User", email, "123456");
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
