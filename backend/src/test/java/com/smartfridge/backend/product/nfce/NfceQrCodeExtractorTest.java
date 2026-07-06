package com.smartfridge.backend.product.nfce;

import com.smartfridge.backend.common.exception.BusinessException;
import java.net.URI;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class NfceQrCodeExtractorTest {

    private final NfceQrCodeExtractor extractor = new NfceQrCodeExtractor();

    @Test
    void shouldExtractPureUrl() {
        URI uri = extractor.extract("https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p=123");

        assertEquals("https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p=123", uri.toString());
    }

    @Test
    void shouldExtractUrlWithUrlPrefix() {
        URI uri = extractor.extract("URL: https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p=123");

        assertEquals("https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p=123", uri.toString());
    }

    @Test
    void shouldExtractUrlWithQrCodePrefixAndLineBreak() {
        URI uri = extractor.extract("QR Code:\nhttps://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p=123");

        assertEquals("https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p=123", uri.toString());
    }

    @Test
    void shouldExtractUrlFromMixedText() {
        URI uri = extractor.extract(
                "Leitura concluida https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p=123 CONSUMIDOR NAO IDENTIFICADO"
        );

        assertEquals("https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p=123", uri.toString());
    }

    @Test
    void shouldExtractEncodedUrlFromPayload() {
        URI uri = extractor.extract("https%3A%2F%2Fwww.sefaz.rs.gov.br%2FNFCE%2FNFCE-COM.aspx%3Fp%3D123");

        assertEquals("https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p=123", uri.toString());
    }

    @Test
    void shouldExtractUrlWithPipeSeparatedPayload() {
        URI uri = extractor.extract(
                "https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p=123|2|1|ABC"
        );

        assertEquals(
                "https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p=123%7C2%7C1%7CABC",
                uri.toString()
        );
    }

    @Test
    void shouldRejectEmptyPayload() {
        assertThrows(BusinessException.class, () -> extractor.extract("   \n  "));
    }

    @Test
    void shouldRejectPayloadWithoutUrl() {
        assertThrows(BusinessException.class, () -> extractor.extract("sem-url"));
    }
}
