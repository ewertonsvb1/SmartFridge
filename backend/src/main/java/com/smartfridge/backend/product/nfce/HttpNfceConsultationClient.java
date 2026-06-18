package com.smartfridge.backend.product.nfce;

import com.smartfridge.backend.common.exception.BusinessException;
import java.text.Normalizer;
import java.net.URI;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
public class HttpNfceConsultationClient implements NfceConsultationClient {

    private final RestClient restClient;

    public HttpNfceConsultationClient(RestClient.Builder builder) {
        this.restClient = builder.build();
    }

    @Override
    public String fetch(URI consultationUri) {
        try {
            String body = restClient.get()
                    .uri(consultationUri)
                    .retrieve()
                    .body(String.class);

            if (body == null || body.isBlank()) {
                throw new BusinessException("NFC-e consultation returned an empty response");
            }

            if (isSecurityVerificationPage(body)) {
                throw new BusinessException("A consulta da NFC-e exige validacao de seguranca");
            }

            return body;
        } catch (RestClientException ex) {
            throw new BusinessException("Unable to consult NFC-e");
        }
    }

    private boolean isSecurityVerificationPage(String body) {
        String stripped = body.replaceAll("(?is)<script.*?</script>", " ")
                .replaceAll("(?is)<style.*?</style>", " ")
                .replaceAll("(?s)<[^>]+>", " ");
        String normalized = Normalizer.normalize(stripped, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "")
                .toLowerCase();

        return (normalized.contains("validacao") && normalized.contains("seguranca"))
                || normalized.contains("efetue a validacao de seguranca")
                || normalized.contains("security verify")
                || normalized.contains("securityverify.aspx");
    }
}
