package com.smartfridge.backend.product.nfce;

import com.smartfridge.backend.common.exception.BusinessException;
import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Component
@Slf4j
public class NfceQrCodeExtractor {

    private static final Pattern PREFIX_PATTERN = Pattern.compile(
            "^(?:(?:url|qrcode|qr\\s*code|link)\\s*:\\s*)+",
            Pattern.CASE_INSENSITIVE
    );
    private static final Pattern MULTIPLE_SPACES_PATTERN = Pattern.compile("\\s+");
    private static final Pattern URL_PATTERN = Pattern.compile("(https?://[^\\s]+)", Pattern.CASE_INSENSITIVE);

    public URI extract(String rawPayload) {
        log.info("NFC-E RAW: {}", rawPayload);

        String normalized = normalizePayload(rawPayload);
        log.info("NFC-E NORMALIZED: {}", normalized);

        if (normalized.isBlank()) {
            throw new BusinessException("QR Code payload is required");
        }

        URI extracted = extractFromText(normalized);
        if (extracted == null) {
            String decoded = normalizePayload(decodeValue(normalized));
            extracted = extractFromText(decoded);
        }

        if (extracted == null) {
            throw new BusinessException("Invalid NFC-e QR Code");
        }

        log.info("NFC-E EXTRACTED URL: {}", extracted);
        return extracted;
    }

    private String normalizePayload(String value) {
        if (value == null) {
            return "";
        }

        String normalized = value
                .trim()
                .replace('\r', ' ')
                .replace('\n', ' ');
        normalized = MULTIPLE_SPACES_PATTERN.matcher(normalized).replaceAll(" ").trim();
        return PREFIX_PATTERN.matcher(normalized).replaceFirst("").trim();
    }

    private String decodeValue(String value) {
        try {
            return URLDecoder.decode(value, StandardCharsets.UTF_8);
        } catch (IllegalArgumentException ex) {
            return value;
        }
    }

    private URI extractFromText(String text) {
        Matcher matcher = URL_PATTERN.matcher(text);
        while (matcher.find()) {
            URI matched = tryCreateHttpUri(matcher.group(1));
            if (matched != null) {
                return matched;
            }
        }
        return null;
    }

    private URI tryCreateHttpUri(String value) {
        String sanitized = sanitizeUrlCandidate(value);
        try {
            return createHttpUri(sanitized);
        } catch (IllegalArgumentException ex) {
            try {
                return createHttpUri(sanitizeUrlCandidate(decodeValue(sanitized)));
            } catch (IllegalArgumentException ignored) {
                return null;
            }
        }
    }

    private String sanitizeUrlCandidate(String value) {
        return value
                .trim()
                .replace("|", "%7C")
                .replace(" ", "%20")
                .replace("\"", "")
                .replace("'", "")
                .replace("<", "")
                .replace(">", "");
    }

    private URI createHttpUri(String value) {
        URI uri = URI.create(value);
        if (uri.getScheme() == null) {
            throw new IllegalArgumentException("URI without scheme");
        }
        if (!"http".equalsIgnoreCase(uri.getScheme()) && !"https".equalsIgnoreCase(uri.getScheme())) {
            throw new IllegalArgumentException("Unsupported URI scheme");
        }
        return uri;
    }
}
