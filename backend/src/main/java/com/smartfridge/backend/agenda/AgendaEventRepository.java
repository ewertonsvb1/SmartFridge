package com.smartfridge.backend.agenda;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface AgendaEventRepository extends JpaRepository<AgendaEventEntity, Long> {

    Optional<AgendaEventEntity> findByIdAndUser_Id(Long id, Long userId);

    @Query("""
            select e
            from AgendaEventEntity e
            where e.user.id = :userId
              and (:status is null or e.status = :status)
              and (:from is null or e.startAt >= :from)
              and (:to is null or e.startAt <= :to)
            order by e.startAt asc
            """)
    List<AgendaEventEntity> findVisibleEvents(
            @Param("userId") Long userId,
            @Param("status") AgendaEventStatus status,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to
    );

    List<AgendaEventEntity> findByStatusAndStartAtLessThanEqual(AgendaEventStatus status, LocalDateTime endAt);
}
