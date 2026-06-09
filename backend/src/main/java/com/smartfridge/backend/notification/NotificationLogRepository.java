package com.smartfridge.backend.notification;

import java.time.LocalDate;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Pageable;

public interface NotificationLogRepository extends JpaRepository<NotificationLogEntity, Long> {

    boolean existsByUser_IdAndProduct_IdAndTypeAndEventDate(
            Long userId,
            Long productId,
            NotificationType type,
            LocalDate eventDate
    );

    boolean existsByUser_IdAndSourceModuleAndSourceIdAndTypeAndEventDate(
            Long userId,
            NotificationSourceModule sourceModule,
            Long sourceId,
            NotificationType type,
            LocalDate eventDate
    );

    List<NotificationLogEntity> findByUser_IdAndIdGreaterThanOrderByIdAsc(Long userId, Long afterId);

    List<NotificationLogEntity> findByUser_IdOrderByIdDesc(Long userId, Pageable pageable);
}
