package com.smartfridge.backend.product.nfce;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class DevNfceFixtureControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void shouldExposeLocalFixturePageAndConsultationWithoutAuth() throws Exception {
        mockMvc.perform(get("/dev/nfce-fixture"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Fixture NFC-e local")))
                .andExpect(content().string(containsString("/dev/nfce-fixture/qr.png")));

        mockMvc.perform(get("/dev/nfce-fixture/consulta"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
                .andExpect(content().string(containsString("<chNFe>42240203821728000172650070000318811000319318</chNFe>")));

        mockMvc.perform(get("/dev/nfce-fixture/qr.png"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.IMAGE_PNG));
    }
}
