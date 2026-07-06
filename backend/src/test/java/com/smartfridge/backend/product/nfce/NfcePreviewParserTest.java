package com.smartfridge.backend.product.nfce;

import com.smartfridge.backend.common.exception.BusinessException;
import java.math.BigDecimal;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class NfcePreviewParserTest {

    private final NfcePreviewParser parser = new NfcePreviewParser();

    @Test
    void shouldParseXmlLikeNfceDocument() {
        String body = """
                <nota>
                  <chNFe>12345678901234567890123456789012345678901234</chNFe>
                  <nNF>98765</nNF>
                  <dhEmi>2026-06-15T10:30:00-03:00</dhEmi>
                  <det nItem="1">
                    <prod>
                      <xProd>Leite Integral</xProd>
                      <qCom>2.0000</qCom>
                    </prod>
                  </det>
                  <det nItem="2">
                    <prod>
                      <xProd>Arroz Tipo 1</xProd>
                      <qCom>1</qCom>
                    </prod>
                  </det>
                </nota>
                """;

        NfceParsedInvoice invoice = parser.parse("https://nfce.example/preview", body);

        assertEquals("https://nfce.example/preview", invoice.sourceUrl());
        assertEquals("12345678901234567890123456789012345678901234", invoice.accessKey());
        assertEquals("98765", invoice.noteNumber());
        assertEquals(LocalDate.of(2026, 6, 15), invoice.emissionDate());
        assertEquals(2, invoice.items().size());
        assertEquals(new BigDecimal("2.0000"), invoice.items().get(0).quantity());
    }

    @Test
    void shouldParseHtmlTableFallback() {
        String body = """
                <html>
                  <body>
                    <time class="issue-date">2026-06-15</time>
                    <table>
                      <tr data-description="Queijo Minas" data-quantity="1"></tr>
                    </table>
                  </body>
                </html>
                """;

        NfceParsedInvoice invoice = parser.parse("https://nfce.example/preview", body);

        assertEquals(LocalDate.of(2026, 6, 15), invoice.emissionDate());
        assertEquals("Queijo Minas", invoice.items().get(0).description());
        assertEquals(new BigDecimal("1"), invoice.items().get(0).quantity());
    }

    @Test
    void shouldParseEmissionDateFromHtmlLabel() {
        String body = """
                <html>
                  <body>
                    <div>Data de Emissao: 15/06/2026 10:30:00</div>
                    <table>
                      <tr data-description="Iogurte Natural" data-quantity="2"></tr>
                    </table>
                  </body>
                </html>
                """;

        NfceParsedInvoice invoice = parser.parse("https://nfce.example/preview", body);

        assertEquals(LocalDate.of(2026, 6, 15), invoice.emissionDate());
        assertEquals("Iogurte Natural", invoice.items().get(0).description());
    }

    @Test
    void shouldParseEmissionDateFromDataHoraLabel() {
        String body = """
                <html>
                  <body>
                    <span>Data/Hora: 15/06/2026 10:30:00</span>
                    <table>
                      <tr data-description="Cafe Torrado" data-quantity="1"></tr>
                    </table>
                  </body>
                </html>
                """;

        NfceParsedInvoice invoice = parser.parse("https://nfce.example/preview", body);

        assertEquals(LocalDate.of(2026, 6, 15), invoice.emissionDate());
        assertEquals("Cafe Torrado", invoice.items().get(0).description());
    }

    @Test
    void shouldRejectDocumentsWithoutItems() {
        String body = """
                <nota>
                  <dhEmi>2026-06-15T10:30:00-03:00</dhEmi>
                </nota>
                """;

        assertThrows(BusinessException.class, () -> parser.parse("https://nfce.example/preview", body));
    }
}
