package com.smartfridge.backend.notification;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartfridge.backend.auth.dto.LoginRequest;
import com.smartfridge.backend.auth.dto.RegisterRequest;
import com.smartfridge.backend.scheduler.ProductStatusScheduler;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class NotificationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private ProductStatusScheduler productStatusScheduler;

    @Test
    void shouldDenyNotificationsWithoutToken() throws Exception {
        mockMvc.perform(get("/notifications"))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    assertTrue(status == 401 || status == 403);
                });
    }

    @Test
    void shouldReturnMultiModuleNotificationsWithoutDailyDuplicates() throws Exception {
        String token = registerAndLogin();
        LocalDate today = LocalDate.now();

        createProduct(token, "Leite", today, today.plusDays(2));
        createEvent(token, "Consulta", today.plusDays(1) + "T09:00:00", today.plusDays(1) + "T10:00:00");
        createBill(token, "Internet", new BigDecimal("120.50"), today.plusDays(1));

        productStatusScheduler.runDailyAutomations();
        productStatusScheduler.runDailyAutomations();

        mockMvc.perform(get("/notifications")
                        .header("Authorization", "Bearer " + token)
                        .param("limit", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(3))
                .andExpect(jsonPath("$[0].sourceModule", is("HOUSE_BILL")))
                .andExpect(jsonPath("$[0].sourceLabel").value("Internet"))
                .andExpect(jsonPath("$[1].sourceModule", is("AGENDA")))
                .andExpect(jsonPath("$[1].sourceLabel").value("Consulta"))
                .andExpect(jsonPath("$[2].sourceModule", is("PRODUCT")))
                .andExpect(jsonPath("$[2].productName").value("Leite"))
                .andExpect(jsonPath("$[2].sourceLabel").value("Leite"))
                .andExpect(jsonPath("$[2].type").value("NEAR_EXPIRATION"));
    }

    private void createProduct(String token, String name, LocalDate manufactureDate, LocalDate expirationDate) throws Exception {
        mockMvc.perform(post("/products")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "%s",
                                  "quantity": 1,
                                  "manufactureDate": "%s",
                                  "expirationDate": "%s"
                                }
                                """.formatted(name, manufactureDate, expirationDate)))
                .andExpect(status().isCreated());
    }

    private void createEvent(String token, String title, String startAt, String endAt) throws Exception {
        mockMvc.perform(post("/agenda/events")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "%s",
                                  "description": "Teste",
                                  "startAt": "%s",
                                  "endAt": "%s",
                                  "status": "SCHEDULED"
                                }
                                """.formatted(title, startAt, endAt)))
                .andExpect(status().isCreated());
    }

    private void createBill(String token, String description, BigDecimal amount, LocalDate dueDate) throws Exception {
        mockMvc.perform(post("/house-bills")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "description": "%s",
                                  "amount": %s,
                                  "dueDate": "%s",
                                  "category": "Casa"
                                }
                                """.formatted(description, amount.toPlainString(), dueDate)))
                .andExpect(status().isCreated());
    }

    private String registerAndLogin() throws Exception {
        String email = "notification_" + UUID.randomUUID() + "@email.com";

        RegisterRequest registerRequest = new RegisterRequest("Notification User", email, "123456");
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
