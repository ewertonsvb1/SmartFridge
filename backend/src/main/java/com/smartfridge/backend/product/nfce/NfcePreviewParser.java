package com.smartfridge.backend.product.nfce;

import com.smartfridge.backend.common.exception.BusinessException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.util.HtmlUtils;

@Component
@Slf4j
public class NfcePreviewParser {

    private static final String DATE_TOKEN_PATTERN = "((?:[0-9]{4}-[0-9]{2}-[0-9]{2})|(?:[0-9]{2}/[0-9]{2}/[0-9]{4}))";
    private static final Pattern ACCESS_KEY_TAG_PATTERN = Pattern.compile("(?i)<chNFe>\\s*([0-9]{44})\\s*</chNFe>");
    private static final Pattern ACCESS_KEY_PATTERN = Pattern.compile("(?i)(?:chNFe|accessKey|chave)[\"'=:\\s]*([0-9]{44})");
    private static final Pattern NOTE_NUMBER_PATTERN = Pattern.compile("(?i)(?:<nNF>\\s*([0-9]{1,9})\\s*</nNF>|(?:nNF|numero|number)[\"'=:\\s]*([0-9]{1,9}))");
    private static final Pattern XML_DHEMI_PATTERN = Pattern.compile(
            "(?i)<dhEmi>\\s*(" + DATE_TOKEN_PATTERN + ")(?:[T\\s][^<]*)?</dhEmi>"
    );
    private static final Pattern ISSUE_DATE_TAG_PATTERN = Pattern.compile(
            "(?i)<time[^>]*class\\s*=\\s*\"[^\"]*issue-date[^\"]*\"[^>]*>\\s*" + DATE_TOKEN_PATTERN + "\\s*</time>"
    );
    private static final List<Pattern> EMISSION_DATE_PATTERNS = Arrays.asList(
            XML_DHEMI_PATTERN,
            ISSUE_DATE_TAG_PATTERN,
            Pattern.compile("(?i)(?:dhEmi|dataEmissao|emissionDate|issueDate)[\"'=:\\s]*" + DATE_TOKEN_PATTERN),
            Pattern.compile("(?i)(?:emiss[aã]o|data\\s+de\\s+emiss[aã]o|data\\s+emissao|emiss[aã]o\\s+em)[^0-9]{0,40}" + DATE_TOKEN_PATTERN),
            Pattern.compile("(?i)data\\s*/\\s*hora[^0-9]{0,40}" + DATE_TOKEN_PATTERN)
    );
    private static final List<DateTimeFormatter> DATE_FORMATTERS = List.of(
            DateTimeFormatter.ISO_LOCAL_DATE,
            DateTimeFormatter.ofPattern("dd/MM/yyyy")
    );
    private static final Pattern DET_BLOCK_PATTERN = Pattern.compile("(?is)<det[^>]*nItem\\s*=\\s*\"?(\\d+)\"?[^>]*>(.*?)</det>");
    private static final Pattern XML_DESCRIPTION_PATTERN = Pattern.compile("(?is)<(?:xProd|descricao)>(.*?)</(?:xProd|descricao)>");
    private static final Pattern XML_QUANTITY_PATTERN = Pattern.compile("(?is)<(?:qCom|qTrib|quantidade)>(.*?)</(?:qCom|qTrib|quantidade)>");
    private static final Pattern ROW_PATTERN = Pattern.compile("(?is)<tr[^>]*>(.*?)</tr>");
    private static final Pattern CELL_PATTERN = Pattern.compile("(?is)<t[dh][^>]*>(.*?)</t[dh]>");
    private static final Pattern ROW_DESCRIPTION_ATTRIBUTE_PATTERN = Pattern.compile("(?i)data-description\\s*=\\s*\"([^\"]+)\"");
    private static final Pattern ROW_QUANTITY_ATTRIBUTE_PATTERN = Pattern.compile("(?i)data-quantity\\s*=\\s*\"([^\"]+)\"");
    private static final Pattern NUMERIC_ROW_QUANTITY_PATTERN = Pattern.compile("^[0-9]+(?:[.,][0-9]+)?$");
    private static final int HTML_PREVIEW_LIMIT = 300;

    public NfceParsedInvoice parse(String sourceUrl, String body) {
        try {
            String normalizedBody = body == null ? "" : body;
            String accessKey = firstMatch(normalizedBody, ACCESS_KEY_TAG_PATTERN);
            if (accessKey == null) {
                accessKey = firstMatch(normalizedBody, ACCESS_KEY_PATTERN);
            }
            String noteNumber = firstMatch(normalizedBody, NOTE_NUMBER_PATTERN);
            String emissionDateCandidate = extractEmissionDateCandidate(normalizedBody);
            log.info("NFC-E DATE CANDIDATE: {}", emissionDateCandidate);
            LocalDate emissionDate = parseDate(emissionDateCandidate);
            List<NfceParsedInvoiceItem> items = extractItems(normalizedBody);

            if (emissionDate == null) {
                logHtmlPreview(normalizedBody);
                throw new BusinessException("NFC-e emission date was not found");
            }
            if (items.isEmpty()) {
                logHtmlPreview(normalizedBody);
                throw new BusinessException("NFC-e does not contain parseable items");
            }

            return new NfceParsedInvoice(sourceUrl, accessKey, noteNumber, emissionDate, List.copyOf(items));
        } catch (RuntimeException ex) {
            log.info("NFC-E PARSE ERROR: {}", ex.getMessage());
            throw ex;
        }
    }

    private List<NfceParsedInvoiceItem> extractItems(String body) {
        List<NfceParsedInvoiceItem> items = new ArrayList<>();

        Matcher detMatcher = DET_BLOCK_PATTERN.matcher(body);
        while (detMatcher.find()) {
            int lineNumber = Integer.parseInt(detMatcher.group(1));
            String block = detMatcher.group(2);
            String description = firstMatch(block, XML_DESCRIPTION_PATTERN);
            String quantityText = firstMatch(block, XML_QUANTITY_PATTERN);
            addItem(items, lineNumber, description, quantityText);
        }

        if (!items.isEmpty()) {
            return items;
        }

        Matcher rowMatcher = ROW_PATTERN.matcher(body);
        int lineNumber = 1;
        while (rowMatcher.find()) {
            String rowMarkup = rowMatcher.group(0);
            String rowContent = rowMatcher.group(1);
            String attributeDescription = firstMatch(rowMarkup, ROW_DESCRIPTION_ATTRIBUTE_PATTERN);
            String attributeQuantity = firstMatch(rowMarkup, ROW_QUANTITY_ATTRIBUTE_PATTERN);
            if (attributeDescription != null && attributeQuantity != null) {
                addItem(items, lineNumber++, attributeDescription, attributeQuantity);
                continue;
            }

            List<String> cells = extractCells(rowContent);
            if (cells.size() < 2) {
                continue;
            }

            String description = cleanText(cells.get(0));
            String quantityText = cleanText(cells.get(1));
            if (!NUMERIC_ROW_QUANTITY_PATTERN.matcher(quantityText).matches()) {
                continue;
            }

            addItem(items, lineNumber++, description, quantityText);
        }

        return items;
    }

    private void addItem(List<NfceParsedInvoiceItem> items, int lineNumber, String description, String quantityText) {
        String cleanedDescription = cleanText(description);
        BigDecimal quantity = parseQuantity(quantityText);
        if (cleanedDescription.isBlank() || quantity == null) {
            return;
        }

        items.add(new NfceParsedInvoiceItem(lineNumber, cleanedDescription, quantity));
    }

    private List<String> extractCells(String row) {
        List<String> cells = new ArrayList<>();
        Matcher cellMatcher = CELL_PATTERN.matcher(row);
        while (cellMatcher.find()) {
            cells.add(cellMatcher.group(1));
        }
        return cells;
    }

    private String firstMatch(String body, Pattern pattern) {
        Matcher matcher = pattern.matcher(body);
        if (!matcher.find()) {
            return null;
        }

        for (int i = 1; i <= matcher.groupCount(); i++) {
            String value = matcher.group(i);
            if (value != null && !value.isBlank()) {
                return value.trim();
            }
        }
        return null;
    }

    private String extractEmissionDateCandidate(String body) {
        for (Pattern pattern : EMISSION_DATE_PATTERNS) {
            String candidate = firstMatch(body, pattern);
            if (candidate != null) {
                return candidate;
            }
        }
        return null;
    }

    private LocalDate parseDate(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }

        String normalized = value.trim();
        for (DateTimeFormatter formatter : DATE_FORMATTERS) {
            try {
                return LocalDate.parse(normalized, formatter);
            } catch (DateTimeParseException ignored) {
                // Try the next supported SEFAZ date layout.
            }
        }
        return null;
    }

    private BigDecimal parseQuantity(String value) {
        if (value == null) {
            return null;
        }

        String normalized = cleanText(value)
                .replace(",", ".")
                .trim();

        if (normalized.isBlank()) {
            return null;
        }

        try {
            return new BigDecimal(normalized);
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private String cleanText(String value) {
        if (value == null) {
            return "";
        }

        String text = HtmlUtils.htmlUnescape(value);
        text = text.replaceAll("(?is)<[^>]+>", " ");
        text = text.replace('\u00A0', ' ');
        return text.replaceAll("\\s+", " ").trim();
    }

    private void logHtmlPreview(String body) {
        String preview = cleanText(body);
        if (preview.length() > HTML_PREVIEW_LIMIT) {
            preview = preview.substring(0, HTML_PREVIEW_LIMIT);
        }
        log.info("NFC-E HTML PREVIEW: {}", preview);
    }
}
