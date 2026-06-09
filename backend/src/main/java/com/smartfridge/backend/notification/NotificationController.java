package com.smartfridge.backend.notification;

import com.smartfridge.backend.notification.dto.NotificationResponse;
import com.smartfridge.backend.security.AuthenticatedUserService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationLogRepository notificationLogRepository;
    private final AuthenticatedUserService authenticatedUserService;

    @GetMapping
    public ResponseEntity<List<NotificationResponse>> list(
            @RequestParam(required = false) Long afterId,
            @RequestParam(defaultValue = "20") int limit
    ) {
        Long userId = authenticatedUserService.getCurrentUser().getId();
        int safeLimit = Math.max(1, Math.min(limit, 100));

        List<NotificationLogEntity> logs;
        if (afterId != null) {
            logs = notificationLogRepository.findByUser_IdAndIdGreaterThanOrderByIdAsc(userId, afterId);
        } else {
            Pageable pageable = PageRequest.of(0, safeLimit);
            logs = notificationLogRepository.findByUser_IdOrderByIdDesc(userId, pageable);
        }

        List<NotificationResponse> response = logs.stream()
                .limit(safeLimit)
                .map(log -> new NotificationResponse(
                        log.getId(),
                        log.getType(),
                        log.getEventDate(),
                        log.getSourceModule().name(),
                        log.getSourceId(),
                        log.getSourceLabel(),
                        log.getSourceDate(),
                        log.getProduct() != null ? log.getProduct().getId() : null,
                        log.getProduct() != null ? log.getProduct().getName() : null,
                        log.getProduct() != null ? log.getProduct().getExpirationDate() : null,
                        log.getCreatedAt()
                ))
                .toList();

        return ResponseEntity.ok(response);
    }
}
