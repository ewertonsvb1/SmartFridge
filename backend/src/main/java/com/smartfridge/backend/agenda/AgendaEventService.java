package com.smartfridge.backend.agenda;

import com.smartfridge.backend.agenda.dto.AgendaEventCreateRequest;
import com.smartfridge.backend.agenda.dto.AgendaEventUpdateRequest;
import com.smartfridge.backend.common.exception.BusinessException;
import com.smartfridge.backend.common.exception.ResourceNotFoundException;
import com.smartfridge.backend.security.AuthenticatedUserService;
import com.smartfridge.backend.user.UserEntity;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AgendaEventService {

    private final AgendaEventRepository agendaEventRepository;
    private final AuthenticatedUserService authenticatedUserService;

    @Transactional
    public AgendaEventEntity create(AgendaEventCreateRequest request) {
        validateTimes(request.startAt(), request.endAt());
        UserEntity user = authenticatedUserService.getCurrentUser();

        AgendaEventEntity entity = new AgendaEventEntity();
        entity.setTitle(request.title());
        entity.setDescription(request.description());
        entity.setStartAt(request.startAt());
        entity.setEndAt(request.endAt());
        entity.setStatus(request.status());
        entity.setUser(user);
        return agendaEventRepository.save(entity);
    }

    @Transactional(readOnly = true)
    public List<AgendaEventEntity> list(LocalDate date, LocalDate startDate, LocalDate endDate, AgendaEventStatus status) {
        RangeFilter filter = resolveRange(date, startDate, endDate);
        Long userId = authenticatedUserService.getCurrentUser().getId();
        return agendaEventRepository.findVisibleEvents(userId, status, filter.from(), filter.to());
    }

    @Transactional(readOnly = true)
    public AgendaEventEntity findById(Long id) {
        Long userId = authenticatedUserService.getCurrentUser().getId();
        return agendaEventRepository.findByIdAndUser_Id(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Agenda event not found"));
    }

    @Transactional
    public AgendaEventEntity update(Long id, AgendaEventUpdateRequest request) {
        validateTimes(request.startAt(), request.endAt());
        AgendaEventEntity entity = findById(id);

        entity.setTitle(request.title());
        entity.setDescription(request.description());
        entity.setStartAt(request.startAt());
        entity.setEndAt(request.endAt());
        entity.setStatus(request.status());
        return agendaEventRepository.save(entity);
    }

    @Transactional
    public void delete(Long id) {
        AgendaEventEntity entity = findById(id);
        agendaEventRepository.delete(entity);
    }

    private void validateTimes(LocalDateTime startAt, LocalDateTime endAt) {
        if (endAt.isBefore(startAt)) {
            throw new BusinessException("Event end cannot be before start");
        }
    }

    private RangeFilter resolveRange(LocalDate date, LocalDate startDate, LocalDate endDate) {
        if (date != null && (startDate != null || endDate != null)) {
            throw new BusinessException("Use either date or date range filters");
        }

        if (date != null) {
            return new RangeFilter(date.atStartOfDay(), date.atTime(LocalTime.MAX));
        }

        if (startDate == null && endDate == null) {
            return new RangeFilter(null, null);
        }

        LocalDate effectiveStart = startDate != null ? startDate : endDate;
        LocalDate effectiveEnd = endDate != null ? endDate : startDate;
        if (effectiveEnd.isBefore(effectiveStart)) {
            throw new BusinessException("End date cannot be before start date");
        }

        return new RangeFilter(effectiveStart.atStartOfDay(), effectiveEnd.atTime(LocalTime.MAX));
    }

    private record RangeFilter(LocalDateTime from, LocalDateTime to) {
    }
}
