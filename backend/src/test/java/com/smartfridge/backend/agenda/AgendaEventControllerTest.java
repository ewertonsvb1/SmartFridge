package com.smartfridge.backend.agenda;

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
class AgendaEventControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void shouldDenyAgendaEndpointsWithoutToken() throws Exception {
        mockMvc.perform(get("/agenda/events"))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    assertTrue(status == 401 || status == 403);
                });
    }

    @Test
    void shouldExecuteAgendaCrudAndFiltersWithAuthenticatedUser() throws Exception {
        String token = registerAndLogin();
        LocalDate today = LocalDate.now();

        long firstId = createEvent(
                token,
                "Consulta medica",
                "Levar exames",
                today.plusDays(1) + "T09:00:00",
                today.plusDays(1) + "T10:00:00",
                "SCHEDULED"
        );
        long secondId = createEvent(
                token,
                "Revisao da casa",
                "",
                today.plusDays(2) + "T14:00:00",
                today.plusDays(2) + "T15:30:00",
                "COMPLETED"
        );

        mockMvc.perform(get("/agenda/events")
                        .header("Authorization", "Bearer " + token)
                        .param("date", today.plusDays(1).toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(firstId))
                .andExpect(jsonPath("$[0].title").value("Consulta medica"));

        mockMvc.perform(get("/agenda/events")
                        .header("Authorization", "Bearer " + token)
                        .param("startDate", today.plusDays(1).toString())
                        .param("endDate", today.plusDays(2).toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2));

        mockMvc.perform(get("/agenda/events")
                        .header("Authorization", "Bearer " + token)
                        .param("status", "COMPLETED"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(secondId));

        mockMvc.perform(get("/agenda/events/{id}", firstId)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SCHEDULED"));

        mockMvc.perform(put("/agenda/events/{id}", firstId)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Consulta medica atualizada",
                                  "description": "Levar exames e receitas",
                                  "startAt": "%s",
                                  "endAt": "%s",
                                  "status": "CANCELED"
                                }
                                """.formatted(
                                today.plusDays(1) + "T11:00:00",
                                today.plusDays(1) + "T12:00:00"
                        )))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title").value("Consulta medica atualizada"))
                .andExpect(jsonPath("$.status").value("CANCELED"));

        mockMvc.perform(delete("/agenda/events/{id}", secondId)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isNoContent());
    }

    @Test
    void shouldRestrictAgendaEventsToAuthenticatedUser() throws Exception {
        String tokenA = registerAndLogin();
        String tokenB = registerAndLogin();
        LocalDate today = LocalDate.now();

        long eventA = createEvent(
                tokenA,
                "Evento usuario A",
                "",
                today.plusDays(1) + "T08:00:00",
                today.plusDays(1) + "T09:00:00",
                "SCHEDULED"
        );
        createEvent(
                tokenB,
                "Evento usuario B",
                "",
                today.plusDays(3) + "T08:00:00",
                today.plusDays(3) + "T09:00:00",
                "SCHEDULED"
        );

        mockMvc.perform(get("/agenda/events")
                        .header("Authorization", "Bearer " + tokenA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].title").value("Evento usuario A"));

        mockMvc.perform(get("/agenda/events/{id}", eventA)
                        .header("Authorization", "Bearer " + tokenB))
                .andExpect(status().isNotFound());
    }

    @Test
    void shouldRejectInvalidAgendaEventTimes() throws Exception {
        String token = registerAndLogin();
        LocalDate today = LocalDate.now();

        mockMvc.perform(post("/agenda/events")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Evento invalido",
                                  "description": "Teste",
                                  "startAt": "%s",
                                  "endAt": "%s",
                                  "status": "SCHEDULED"
                                }
                                """.formatted(
                                today.plusDays(1) + "T15:00:00",
                                today.plusDays(1) + "T14:00:00"
                        )))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Event end cannot be before start"));
    }

    @Test
    void shouldRejectConflictingDateFilters() throws Exception {
        String token = registerAndLogin();
        LocalDate today = LocalDate.now();

        mockMvc.perform(get("/agenda/events")
                        .header("Authorization", "Bearer " + token)
                        .param("date", today.toString())
                        .param("startDate", today.plusDays(1).toString()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Use either date or date range filters"));
    }

    private long createEvent(
            String token,
            String title,
            String description,
            String startAt,
            String endAt,
            String status
    ) throws Exception {
        MvcResult result = mockMvc.perform(post("/agenda/events")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "%s",
                                  "description": "%s",
                                  "startAt": "%s",
                                  "endAt": "%s",
                                  "status": "%s"
                                }
                                """.formatted(title, description, startAt, endAt, status)))
                .andExpect(status().isCreated())
                .andReturn();

        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        return body.get("id").asLong();
    }

    private String registerAndLogin() throws Exception {
        String email = "agenda_" + UUID.randomUUID() + "@email.com";

        RegisterRequest registerRequest = new RegisterRequest("Agenda User", email, "123456");
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
