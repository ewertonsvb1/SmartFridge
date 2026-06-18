package com.smartfridge.backend.product.nfce;

import com.smartfridge.backend.common.exception.BusinessException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

class HttpNfceConsultationClientTest {

    @Test
    void shouldRejectSecurityVerificationPageWithClearMessage() {
        RestClient.Builder builder = RestClient.builder();
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        HttpNfceConsultationClient client = new HttpNfceConsultationClient(builder);
        URI uri = URI.create("https://sat.sef.sc.gov.br/nfce/consulta?p=abc");

        server.expect(requestTo(uri))
                .andExpect(method(org.springframework.http.HttpMethod.GET))
                .andRespond(withSuccess("""
                        <html>
                          <body>
                            <h1>Validação de segurança</h1>
                            <p>Efetue a validação de segurança.</p>
                          </body>
                        </html>
                        """, new MediaType("text", "html", StandardCharsets.UTF_8)));

        BusinessException ex = assertThrows(BusinessException.class, () -> client.fetch(uri));

        assertEquals("A consulta da NFC-e exige validacao de seguranca", ex.getMessage());
        server.verify();
    }
}
