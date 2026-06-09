package com.smartfridge.backend.agenda;

import com.smartfridge.backend.agenda.dto.AgendaEventResponse;
import org.springframework.stereotype.Component;

@Component
public class AgendaEventMapper {

    public AgendaEventResponse toResponse(AgendaEventEntity entity) {
        return new AgendaEventResponse(
                entity.getId(),
                entity.getTitle(),
                entity.getDescription(),
                entity.getStartAt(),
                entity.getEndAt(),
                entity.getStatus(),
                entity.getUser().getId(),
                entity.getCreatedAt()
        );
    }
}
