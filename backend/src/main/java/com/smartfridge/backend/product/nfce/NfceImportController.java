package com.smartfridge.backend.product.nfce;

import com.smartfridge.backend.product.nfce.dto.NfceImportConfirmRequest;
import com.smartfridge.backend.product.nfce.dto.NfceImportConfirmResponse;
import com.smartfridge.backend.product.nfce.dto.NfceImportPreviewRequest;
import com.smartfridge.backend.product.nfce.dto.NfceImportPreviewResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/products/nfce")
@RequiredArgsConstructor
public class NfceImportController {

    private final NfceImportPreviewService nfceImportPreviewService;
    private final NfceImportConfirmService nfceImportConfirmService;

    @PostMapping("/preview")
    public ResponseEntity<NfceImportPreviewResponse> preview(@Valid @RequestBody NfceImportPreviewRequest request) {
        return ResponseEntity.ok(nfceImportPreviewService.preview(request));
    }

    @PostMapping("/confirm")
    public ResponseEntity<NfceImportConfirmResponse> confirm(@Valid @RequestBody NfceImportConfirmRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(nfceImportConfirmService.confirm(request));
    }
}
