package com.smartfridge.backend.housebill;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface HouseBillRepository extends JpaRepository<HouseBillEntity, Long> {

    Optional<HouseBillEntity> findByIdAndUser_Id(Long id, Long userId);

    List<HouseBillEntity> findByUser_IdOrderByDueDateAsc(Long userId);

    List<HouseBillEntity> findByPaidAtIsNullAndDueDateLessThanEqual(LocalDate dueDate);
}
