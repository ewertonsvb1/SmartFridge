package com.smartfridge.backend.product.nfce;

import com.smartfridge.backend.common.exception.BusinessException;
import java.net.URI;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class NfceQrCodeExtractorTest {

    private final NfceQrCodeExtractor extractor = new NfceQrCodeExtractor();

    @Test
    void shouldReturnDirectUrl() {
        URI uri = extractor.extract("https://nfce.example/preview");

        assertEquals("https://nfce.example/preview", uri.toString());
    }

    @Test
    void shouldExtractUrlFromEncodedPayload() {
        URI uri = extractor.extract("p=https%3A%2F%2Fnfce.example%2Fpreview%3FchNFe%3D123");

        assertEquals("https://nfce.example/preview?chNFe=123", uri.toString());
    }

    @Test
    void shouldExtractUrlWithPipeSeparatedNfcePayload() {
        URI uri = extractor.extract(
                "https://sat.sef.sc.gov.br/nfce/consulta?p=42240203821728000172650070000318811000319318|2|1|1|79BCB6C4DDFB13D9BA0D1F84D96F9B6B3E8382EA"
        );

        assertEquals(
                "https://sat.sef.sc.gov.br/nfce/consulta?p=42240203821728000172650070000318811000319318%7C2%7C1%7C1%7C79BCB6C4DDFB13D9BA0D1F84D96F9B6B3E8382EA",
                uri.toString()
        );
    }

    @Test
    void shouldRejectInvalidPayload() {
        assertThrows(BusinessException.class, () -> extractor.extract("sem-url"));
    }
}
