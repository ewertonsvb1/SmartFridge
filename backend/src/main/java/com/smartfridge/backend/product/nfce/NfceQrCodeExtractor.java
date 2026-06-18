package com.smartfridge.backend.product.nfce;

import com.smartfridge.backend.common.exception.BusinessException;
import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.stereotype.Component;

@Component
public class NfceQrCodeExtractor {

    private static final Pattern URL_PATTERN = Pattern.compile("https?://[^\\s\"'<>]+", Pattern.CASE_INSENSITIVE);

    public URI extract(String rawPayload) {
        String normalized = rawPayload == null ? "" : rawPayload.trim();
        if (normalized.isBlank()) {
            throw new BusinessException("QR Code payload is required");
        }

        URI direct = tryCreateHttpUri(normalized);
        if (direct != null) {
            return direct;
        }

        String decoded = URLDecoder.decode(normalized, StandardCharsets.UTF_8);
        URI decodedUri = tryCreateHttpUri(decoded);
        if (decodedUri != null) {
            return decodedUri;
        }

        Matcher matcher = URL_PATTERN.matcher(decoded);
        if (matcher.find()) {
            URI matched = tryCreateHttpUri(matcher.group());
            if (matched != null) {
                return matched;
            }
        }

        throw new BusinessException("Invalid NFC-e QR Code");
    }

    private URI tryCreateHttpUri(String value) {
        try {
            URI uri = URI.create(value);
            if (uri.getScheme() == null) {
                return null;
            }
            if (!"http".equalsIgnoreCase(uri.getScheme()) && !"https".equalsIgnoreCase(uri.getScheme())) {
                return null;
            }
            return uri;
        } catch (IllegalArgumentException ex) {
            String sanitized = value.replace("|", "%7C");
            try {
                URI uri = URI.create(sanitized);
                if (uri.getScheme() == null) {
                    return null;
                }
                if (!"http".equalsIgnoreCase(uri.getScheme()) && !"https".equalsIgnoreCase(uri.getScheme())) {
                    return null;
                }
                return uri;
            } catch (IllegalArgumentException ignored) {
                return null;
            }
        }
    }
}
