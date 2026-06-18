package com.smartfridge.backend.product.nfce;

import com.smartfridge.backend.product.nfce.dto.NfceImportPreviewRequest;
import java.math.BigDecimal;
import java.net.URI;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NfceImportPreviewServiceTest {

    @Mock
    private NfceQrCodeExtractor qrCodeExtractor;

    @Mock
    private NfceConsultationClient nfceConsultationClient;

    @Mock
    private NfcePreviewParser nfcePreviewParser;

    private final ShelfLifeSuggestionResolver shelfLifeSuggestionResolver =
            new DefaultShelfLifeSuggestionResolver(new ShelfLifeRuleCatalog(new com.fasterxml.jackson.databind.ObjectMapper()));

    private NfceImportPreviewService nfceImportPreviewService;

    @org.junit.jupiter.api.BeforeEach
    void setUp() {
        nfceImportPreviewService = new NfceImportPreviewService(
                qrCodeExtractor,
                nfceConsultationClient,
                nfcePreviewParser,
                shelfLifeSuggestionResolver
        );
    }

    @Test
    void shouldBuildPreviewUsingShelfLifeSuggestions() {
        URI uri = URI.create("https://nfce.example/preview");
        String body = "<nota></nota>";
        NfceParsedInvoice invoice = new NfceParsedInvoice(
                uri.toString(),
                "12345678901234567890123456789012345678901234",
                "12345",
                LocalDate.of(2026, 6, 15),
                List.of(
                        new NfceParsedInvoiceItem(1, "Leite", new BigDecimal("2")),
                        new NfceParsedInvoiceItem(2, "Manteiga", new BigDecimal("1"))
                )
        );

        when(qrCodeExtractor.extract(anyString())).thenReturn(uri);
        when(nfceConsultationClient.fetch(uri)).thenReturn(body);
        when(nfcePreviewParser.parse(uri.toString(), body)).thenReturn(invoice);

        var response = nfceImportPreviewService.preview(new NfceImportPreviewRequest("https://nfce.example/preview"));

        assertEquals("12345", response.noteNumber());
        assertEquals(2, response.items().size());
        assertEquals(LocalDate.of(2026, 6, 22), response.items().get(0).suggestedExpirationDate());
        assertEquals("LEITE_7_DIAS", response.items().get(0).shelfLifeRuleCode());
        assertFalse(response.items().get(0).manualReviewRequired());
        assertTrue(response.items().get(1).manualReviewRequired());
    }
}
