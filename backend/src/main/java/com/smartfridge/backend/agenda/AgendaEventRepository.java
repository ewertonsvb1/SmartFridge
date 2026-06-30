package com.smartfridge.backend.agenda;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface AgendaEventRepository extends JpaRepository<AgendaEventEntity, Long>,
        JpaSpecificationExecutor<AgendaEventEntity> {

    Optional<AgendaEventEntity> findByIdAndUser_Id(Long id, Long userId);

    List<AgendaEventEntity> findByStatusAndStartAtLessThanEqual(AgendaEventStatus status, LocalDateTime endAt);
}
