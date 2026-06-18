package com.smartfridge.backend.product.nfce;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartfridge.backend.auth.dto.LoginRequest;
import com.smartfridge.backend.auth.dto.RegisterRequest;
import com.smartfridge.backend.product.nfce.dto.NfceImportPreviewItemResponse;
import com.smartfridge.backend.product.nfce.dto.NfceImportPreviewRequest;
import com.smartfridge.backend.product.nfce.dto.NfceImportPreviewResponse;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.is;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class NfceImportControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private NfceImportPreviewService nfceImportPreviewService;

    @Test
    void shouldDenyPreviewWithoutToken() throws Exception {
        mockMvc.perform(post("/products/nfce/preview")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "qrCodePayload": "https://nfce.example/preview"
                                }
                                """))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    org.junit.jupiter.api.Assertions.assertTrue(status == 401 || status == 403);
                });
    }

    @Test
    void shouldReturnPreviewWithAuthenticatedUser() throws Exception {
        String token = registerAndLogin();

        when(nfceImportPreviewService.preview(any(NfceImportPreviewRequest.class))).thenReturn(
                new NfceImportPreviewResponse(
                        "https://nfce.example/preview",
                        "12345678901234567890123456789012345678901234",
                        "12345",
                        LocalDate.of(2026, 6, 15),
                        List.of(
                                new NfceImportPreviewItemResponse(
                                        1,
                                        "Leite Integral",
                                        new BigDecimal("2"),
                                        LocalDate.of(2026, 6, 15),
                                        LocalDate.of(2026, 6, 22),
                                        7,
                                        "LEITE_7_DIAS",
                                        false
                                )
                        )
                )
        );

        mockMvc.perform(post("/products/nfce/preview")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "qrCodePayload": "https://nfce.example/preview"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.sourceUrl", is("https://nfce.example/preview")))
                .andExpect(jsonPath("$.noteNumber", is("12345")))
                .andExpect(jsonPath("$.items[0].description", is("Leite Integral")))
                .andExpect(jsonPath("$.items[0].suggestedExpirationDate", is("2026-06-22")));
    }

    private String registerAndLogin() throws Exception {
        String email = "nfce_" + UUID.randomUUID() + "@email.com";

        RegisterRequest registerRequest = new RegisterRequest("NFCE User", email, "123456");
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
