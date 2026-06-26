package com.smartfridge.backend;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;

@SpringBootTest(properties = {
        "DB_URL=jdbc:h2:mem:actuatortest;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE",
        "DB_USER=sa",
        "DB_PASS=",
        "JWT_SECRET=test-only-secret-with-at-least-32-chars",
        "CORS_ALLOWED_ORIGINS=http://localhost:*",
        "spring.datasource.driver-class-name=org.h2.Driver"
})
@ActiveProfiles("prod")
@AutoConfigureMockMvc
class ActuatorSecurityTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void shouldExposeHealthcheckWithoutAuthentication() throws Exception {
        mockMvc.perform(get("/actuator/health"))
                .andExpect(result -> assertTrue(result.getResponse().getStatus() == 200));
    }

    @Test
    void shouldKeepBusinessEndpointsProtectedInProd() throws Exception {
        mockMvc.perform(get("/products"))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    assertTrue(status == 401 || status == 403);
                });
    }
}
