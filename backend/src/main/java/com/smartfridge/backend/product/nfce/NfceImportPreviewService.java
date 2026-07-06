package com.smartfridge.backend.product.nfce;

import com.smartfridge.backend.product.nfce.dto.NfceImportPreviewItemResponse;
import com.smartfridge.backend.product.nfce.dto.NfceImportPreviewRequest;
import com.smartfridge.backend.product.nfce.dto.NfceImportPreviewResponse;
import java.net.URI;
import java.time.LocalDate;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class NfceImportPreviewService {

    private final NfceQrCodeExtractor qrCodeExtractor;
    private final NfceConsultationClient nfceConsultationClient;
    private final NfcePreviewParser nfcePreviewParser;
    private final ShelfLifeSuggestionResolver shelfLifeSuggestionResolver;

    @Transactional(readOnly = true)
    public NfceImportPreviewResponse preview(NfceImportPreviewRequest request) {
        URI consultationUri = qrCodeExtractor.extract(request.qrCodePayload());
        log.info("NFC-E URL EXTRAIDA: {}", consultationUri);
        String consultationBody = nfceConsultationClient.fetch(consultationUri);
        NfceParsedInvoice invoice = nfcePreviewParser.parse(consultationUri.toString(), consultationBody);

        List<NfceImportPreviewItemResponse> items = invoice.items().stream()
                .map(item -> toResponseItem(invoice.emissionDate(), item))
                .toList();

        return new NfceImportPreviewResponse(
                invoice.sourceUrl(),
                invoice.accessKey(),
                invoice.noteNumber(),
                invoice.emissionDate(),
                items
        );
    }

    private NfceImportPreviewItemResponse toResponseItem(LocalDate emissionDate, NfceParsedInvoiceItem item) {
        return shelfLifeSuggestionResolver.resolve(item.description())
                .map(match -> new NfceImportPreviewItemResponse(
                        item.lineNumber(),
                        item.description(),
                        item.quantity(),
                        emissionDate,
                        emissionDate.plusDays(match.suggestion().shelfLifeDays()),
                        match.suggestion().shelfLifeDays(),
                        match.suggestion().ruleCode(),
                        false
                ))
                .orElseGet(() -> new NfceImportPreviewItemResponse(
                        item.lineNumber(),
                        item.description(),
                        item.quantity(),
                        emissionDate,
                        null,
                        null,
                        null,
                        true
                ));
    }
}
