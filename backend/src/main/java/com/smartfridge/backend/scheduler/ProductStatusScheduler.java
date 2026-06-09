package com.smartfridge.backend.scheduler;

import com.smartfridge.backend.agenda.AgendaEventEntity;
import com.smartfridge.backend.agenda.AgendaEventRepository;
import com.smartfridge.backend.agenda.AgendaEventStatus;
import com.smartfridge.backend.housebill.HouseBillEntity;
import com.smartfridge.backend.housebill.HouseBillRepository;
import com.smartfridge.backend.notification.NotificationLogService;
import com.smartfridge.backend.notification.NotificationSourceModule;
import com.smartfridge.backend.notification.NotificationType;
import com.smartfridge.backend.product.ProductService;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@RequiredArgsConstructor
@Slf4j
public class ProductStatusScheduler {

    private static final int URGENT_WINDOW_DAYS = 3;

    private final ProductService productService;
    private final AgendaEventRepository agendaEventRepository;
    private final HouseBillRepository houseBillRepository;
    private final NotificationLogService notificationLogService;

    @Transactional
    @Scheduled(cron = "0 0 2 * * *")
    public void runDailyAutomations() {
        productService.recalculateAllStatusesAndPrepareLogs();
        createAgendaNotifications();
        createHouseBillNotifications();
        log.info("Daily SmartHouse automations executed");
    }

    private void createAgendaNotifications() {
        LocalDate today = LocalDate.now();
        LocalDateTime limit = today.plusDays(URGENT_WINDOW_DAYS).atTime(LocalTime.MAX);
        List<AgendaEventEntity> urgentEvents = agendaEventRepository.findByStatusAndStartAtLessThanEqual(
                AgendaEventStatus.SCHEDULED,
                limit
        );

        for (AgendaEventEntity event : urgentEvents) {
            LocalDate eventDate = event.getStartAt().toLocalDate();
            NotificationType type = eventDate.isBefore(today)
                    ? NotificationType.EXPIRED
                    : NotificationType.NEAR_EXPIRATION;
            notificationLogService.registerIfNotExists(
                    event.getUser(),
                    NotificationSourceModule.AGENDA,
                    event.getId(),
                    type,
                    today,
                    event.getTitle(),
                    eventDate
            );
        }
    }

    private void createHouseBillNotifications() {
        LocalDate today = LocalDate.now();
        LocalDate limit = today.plusDays(URGENT_WINDOW_DAYS);
        List<HouseBillEntity> urgentBills = houseBillRepository.findByPaidAtIsNullAndDueDateLessThanEqual(limit);

        for (HouseBillEntity bill : urgentBills) {
            NotificationType type = bill.getDueDate().isBefore(today)
                    ? NotificationType.EXPIRED
                    : NotificationType.NEAR_EXPIRATION;
            notificationLogService.registerIfNotExists(
                    bill.getUser(),
                    NotificationSourceModule.HOUSE_BILL,
                    bill.getId(),
                    type,
                    today,
                    bill.getDescription(),
                    bill.getDueDate()
            );
        }
    }
}
