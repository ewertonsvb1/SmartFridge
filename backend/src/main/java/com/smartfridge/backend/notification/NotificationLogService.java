package com.smartfridge.backend.notification;

import com.smartfridge.backend.product.ProductEntity;
import com.smartfridge.backend.user.UserEntity;
import java.time.LocalDate;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class NotificationLogService {

    private final NotificationLogRepository notificationLogRepository;

    public void registerIfNotExists(ProductEntity product, NotificationType type) {
        registerIfNotExists(
                product.getUser(),
                NotificationSourceModule.PRODUCT,
                product.getId(),
                type,
                LocalDate.now(),
                product.getName(),
                product.getExpirationDate(),
                product
        );
    }

    public void registerIfNotExists(
            UserEntity user,
            NotificationSourceModule sourceModule,
            Long sourceId,
            NotificationType type,
            LocalDate eventDate,
            String sourceLabel,
            LocalDate sourceDate
    ) {
        registerIfNotExists(user, sourceModule, sourceId, type, eventDate, sourceLabel, sourceDate, null);
    }

    private void registerIfNotExists(
            UserEntity user,
            NotificationSourceModule sourceModule,
            Long sourceId,
            NotificationType type,
            LocalDate eventDate,
            String sourceLabel,
            LocalDate sourceDate,
            ProductEntity product
    ) {
        boolean exists = notificationLogRepository.existsByUser_IdAndSourceModuleAndSourceIdAndTypeAndEventDate(
                user.getId(),
                sourceModule,
                sourceId,
                type,
                eventDate
        );

        if (!exists) {
            NotificationLogEntity log = new NotificationLogEntity();
            log.setUser(user);
            log.setSourceModule(sourceModule);
            log.setSourceId(sourceId);
            log.setSourceLabel(sourceLabel);
            log.setSourceDate(sourceDate);
            log.setType(type);
            log.setEventDate(eventDate);
            log.setProduct(product);
            notificationLogRepository.save(log);
        }
    }
}
