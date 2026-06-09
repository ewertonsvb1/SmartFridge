package com.smartfridge.backend.housebill;

import com.smartfridge.backend.housebill.dto.HouseBillResponse;
import java.time.LocalDate;
import org.springframework.stereotype.Component;

@Component
public class HouseBillMapper {

    public HouseBillResponse toResponse(HouseBillEntity entity) {
        return new HouseBillResponse(
                entity.getId(),
                entity.getDescription(),
                entity.getAmount(),
                entity.getDueDate(),
                entity.getCategory(),
                resolveStatus(entity),
                entity.getPaidAt(),
                entity.getUser().getId(),
                entity.getCreatedAt()
        );
    }

    HouseBillStatus resolveStatus(HouseBillEntity entity) {
        if (entity.getPaidAt() != null) {
            return HouseBillStatus.PAID;
        }

        if (entity.getDueDate().isBefore(LocalDate.now())) {
            return HouseBillStatus.OVERDUE;
        }

        return HouseBillStatus.OPEN;
    }
}
