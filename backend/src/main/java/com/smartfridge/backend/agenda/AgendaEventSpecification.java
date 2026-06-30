package com.smartfridge.backend.agenda;

import java.time.LocalDateTime;
import org.springframework.data.jpa.domain.Specification;

public final class AgendaEventSpecification {

    private AgendaEventSpecification() {
    }

    public static Specification<AgendaEventEntity> belongsToUser(Long userId) {
        return (root, query, cb) -> cb.equal(root.get("user").get("id"), userId);
    }

    public static Specification<AgendaEventEntity> withStatus(AgendaEventStatus status) {
        return (root, query, cb) -> cb.equal(root.get("status"), status);
    }

    public static Specification<AgendaEventEntity> startsAtOrAfter(LocalDateTime from) {
        return (root, query, cb) -> cb.greaterThanOrEqualTo(root.get("startAt"), from);
    }

    public static Specification<AgendaEventEntity> startsAtOrBefore(LocalDateTime to) {
        return (root, query, cb) -> cb.lessThanOrEqualTo(root.get("startAt"), to);
    }
}
