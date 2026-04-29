package com.smartfridge.backend.notification;

import com.smartfridge.backend.product.ProductEntity;
import java.time.LocalDate;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class NotificationLogService {

    private final NotificationLogRepository notificationLogRepository;

    public void registerIfNotExists(ProductEntity product, NotificationType type) {
        LocalDate today = LocalDate.now();
        boolean exists = notificationLogRepository.existsByUser_IdAndProduct_IdAndTypeAndEventDate(
                product.getUser().getId(),
                product.getId(),
                type,
                today
        );

        if (!exists) {
            NotificationLogEntity log = new NotificationLogEntity();
            log.setUser(product.getUser());
            log.setProduct(product);
            log.setType(type);
            log.setEventDate(today);
            notificationLogRepository.save(log);
        }
    }
}
