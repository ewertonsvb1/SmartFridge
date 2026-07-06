package com.smartfridge.backend.product.nfce;

import com.smartfridge.backend.common.exception.BusinessException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.text.Normalizer;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
@Slf4j
public class HttpNfceConsultationClient implements NfceConsultationClient {

    private static final int RESPONSE_PREVIEW_LIMIT = 300;

    private final RestClient restClient;

    public HttpNfceConsultationClient(RestClient.Builder builder) {
        this.restClient = builder.build();
    }

    @Override
    public String fetch(URI consultationUri) {
        try {
            log.info("NFC-E CONSULTANDO URL: {}", consultationUri);

            HttpResponseSnapshot response = restClient.get()
                    .uri(consultationUri)
                    .exchange((request, clientResponse) -> {
                        HttpStatusCode statusCode = clientResponse.getStatusCode();
                        HttpHeaders headers = clientResponse.getHeaders();
                        MediaType contentType = headers.getContentType();
                        String body = new String(clientResponse.getBody().readAllBytes(), StandardCharsets.UTF_8);
                        String redirectTarget = headers.getFirst(HttpHeaders.LOCATION);

                        log.info("NFC-E STATUS: {}", statusCode.value());
                        log.info("NFC-E CONTENT-TYPE: {}", contentType);
                        log.info("NFC-E RESPONSE SIZE: {}", body.length());
                        if (redirectTarget != null && !redirectTarget.isBlank()) {
                            log.info("NFC-E REDIRECT: {}", redirectTarget);
                        }

                        return new HttpResponseSnapshot(statusCode, headers, body);
                    });

            String body = response.body();

            if (body == null || body.isBlank()) {
                throw new BusinessException("NFC-e consultation returned an empty response");
            }

            if (isSecurityVerificationPage(body)) {
                log.info("NFC-E SECURITY VALIDATION TRIGGERED");
                log.info("NFC-E URL: {}", consultationUri);
                log.info("NFC-E HTTP STATUS: {}", response.statusCode().value());
                log.info("NFC-E RESPONSE HEADERS: {}", response.headers());
                log.info("NFC-E RESPONSE PREVIEW: {}", preview(body));
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

    private String preview(String body) {
        String normalized = body.replaceAll("\\s+", " ").trim();
        if (normalized.length() > RESPONSE_PREVIEW_LIMIT) {
            return normalized.substring(0, RESPONSE_PREVIEW_LIMIT);
        }
        return normalized;
    }

    private record HttpResponseSnapshot(HttpStatusCode statusCode, HttpHeaders headers, String body) {
    }
}
