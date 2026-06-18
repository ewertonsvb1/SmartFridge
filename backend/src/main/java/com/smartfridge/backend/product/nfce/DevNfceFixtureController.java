package com.smartfridge.backend.product.nfce;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.WriterException;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Profile("dev")
@RestController
@RequestMapping("/dev/nfce-fixture")
public class DevNfceFixtureController {

    private static final String CONSULTATION_URL =
            "http://127.0.0.1:8080/dev/nfce-fixture/consulta";

    private static final String CONSULTATION_BODY = """
            <nota>
              <chNFe>42240203821728000172650070000318811000319318</chNFe>
              <nNF>31881</nNF>
              <dhEmi>2026-06-15T10:30:00-03:00</dhEmi>
              <det nItem="1">
                <prod>
                  <xProd>Leite Integral</xProd>
                  <qCom>2.0000</qCom>
                </prod>
              </det>
              <det nItem="2">
                <prod>
                  <xProd>Iogurte Natural</xProd>
                  <qCom>4.0000</qCom>
                </prod>
              </det>
              <det nItem="3">
                <prod>
                  <xProd>Arroz Tipo 1</xProd>
                  <qCom>1</qCom>
                </prod>
              </det>
            </nota>
            """;

    private static final byte[] QR_CODE_PNG = createQrCode(CONSULTATION_URL);

    @GetMapping(produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> page() {
        String html = """
                <!doctype html>
                <html lang="pt-BR">
                <head>
                  <meta charset="utf-8">
                  <title>Fixture NFC-e local</title>
                  <style>
                    body { font-family: Arial, sans-serif; margin: 32px; }
                    .card { max-width: 720px; padding: 24px; border: 1px solid #ddd; border-radius: 16px; }
                    img { width: 320px; height: 320px; image-rendering: pixelated; }
                    code { background: #f4f4f4; padding: 8px; border-radius: 8px; display: block; overflow-x: auto; }
                  </style>
                </head>
                <body>
                  <div class="card">
                    <h1>Fixture NFC-e local</h1>
                    <p>Abra esta pagina, mostre o QR abaixo em outro device e escaneie pelo app.</p>
                    <img src="/dev/nfce-fixture/qr.png" alt="QR Code NFC-e local" />
                    <h2>Consulta</h2>
                    <code>%s</code>
                  </div>
                </body>
                </html>
                """.formatted(CONSULTATION_URL);

        return ResponseEntity.ok()
                .contentType(MediaType.TEXT_HTML)
                .body(html);
    }

    @GetMapping(value = "/consulta", produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> consultation() {
        return ResponseEntity.ok()
                .contentType(new MediaType("text", "html", StandardCharsets.UTF_8))
                .body(CONSULTATION_BODY);
    }

    @GetMapping(value = "/qr.png", produces = MediaType.IMAGE_PNG_VALUE)
    public ResponseEntity<byte[]> qrCode() {
        return ResponseEntity.ok()
                .header(HttpHeaders.CACHE_CONTROL, "no-store")
                .contentType(MediaType.IMAGE_PNG)
                .body(QR_CODE_PNG);
    }

    private static byte[] createQrCode(String content) {
        try {
            BitMatrix matrix = new QRCodeWriter().encode(content, BarcodeFormat.QR_CODE, 320, 320);
            try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
                MatrixToImageWriter.writeToStream(matrix, "PNG", outputStream);
                return outputStream.toByteArray();
            }
        } catch (WriterException | IOException ex) {
            throw new IllegalStateException("Failed to generate dev NFC-e QR code", ex);
        }
    }
}
