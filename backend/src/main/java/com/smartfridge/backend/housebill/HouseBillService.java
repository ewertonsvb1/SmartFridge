package com.smartfridge.backend.housebill;

import com.smartfridge.backend.common.exception.BusinessException;
import com.smartfridge.backend.common.exception.ResourceNotFoundException;
import com.smartfridge.backend.housebill.dto.HouseBillCreateRequest;
import com.smartfridge.backend.housebill.dto.HouseBillDashboardResponse;
import com.smartfridge.backend.housebill.dto.HouseBillUpdateRequest;
import com.smartfridge.backend.security.AuthenticatedUserService;
import com.smartfridge.backend.user.UserEntity;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class HouseBillService {

    private final HouseBillRepository houseBillRepository;
    private final AuthenticatedUserService authenticatedUserService;

    @Transactional
    public HouseBillEntity create(HouseBillCreateRequest request) {
        validateAmount(request.amount());
        UserEntity user = authenticatedUserService.getCurrentUser();

        HouseBillEntity entity = new HouseBillEntity();
        entity.setDescription(request.description());
        entity.setAmount(request.amount());
        entity.setDueDate(request.dueDate());
        entity.setCategory(request.category());
        entity.setUser(user);
        return houseBillRepository.save(entity);
    }

    @Transactional(readOnly = true)
    public List<HouseBillEntity> list(HouseBillStatus status, LocalDate startDate, LocalDate endDate) {
        RangeFilter range = resolveRange(startDate, endDate);
        Long userId = authenticatedUserService.getCurrentUser().getId();

        return houseBillRepository.findByUser_IdOrderByDueDateAsc(userId).stream()
                .filter(entity -> isWithinRange(entity, range))
                .filter(entity -> status == null || resolveStatus(entity) == status)
                .sorted(Comparator.comparing(HouseBillEntity::getDueDate)
                        .thenComparing(HouseBillEntity::getCreatedAt))
                .toList();
    }

    @Transactional(readOnly = true)
    public HouseBillEntity findById(Long id) {
        Long userId = authenticatedUserService.getCurrentUser().getId();
        return houseBillRepository.findByIdAndUser_Id(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("House bill not found"));
    }

    @Transactional
    public HouseBillEntity update(Long id, HouseBillUpdateRequest request) {
        validateAmount(request.amount());
        HouseBillEntity entity = findById(id);

        entity.setDescription(request.description());
        entity.setAmount(request.amount());
        entity.setDueDate(request.dueDate());
        entity.setCategory(request.category());
        return houseBillRepository.save(entity);
    }

    @Transactional
    public HouseBillEntity markAsPaid(Long id) {
        HouseBillEntity entity = findById(id);
        if (entity.getPaidAt() == null) {
            entity.setPaidAt(LocalDate.now());
        }
        return houseBillRepository.save(entity);
    }

    @Transactional
    public void delete(Long id) {
        HouseBillEntity entity = findById(id);
        houseBillRepository.delete(entity);
    }

    @Transactional(readOnly = true)
    public HouseBillDashboardResponse dashboard(LocalDate startDate, LocalDate endDate) {
        List<HouseBillEntity> bills = list(null, startDate, endDate);
        long totalCount = bills.size();
        long openCount = bills.stream().filter(bill -> resolveStatus(bill) == HouseBillStatus.OPEN).count();
        long overdueCount = bills.stream().filter(bill -> resolveStatus(bill) == HouseBillStatus.OVERDUE).count();
        long paidCount = bills.stream().filter(bill -> resolveStatus(bill) == HouseBillStatus.PAID).count();

        BigDecimal totalAmount = sumAmount(bills);
        BigDecimal openAmount = sumAmount(bills.stream()
                .filter(bill -> resolveStatus(bill) == HouseBillStatus.OPEN)
                .toList());
        BigDecimal overdueAmount = sumAmount(bills.stream()
                .filter(bill -> resolveStatus(bill) == HouseBillStatus.OVERDUE)
                .toList());
        BigDecimal paidAmount = sumAmount(bills.stream()
                .filter(bill -> resolveStatus(bill) == HouseBillStatus.PAID)
                .toList());

        return new HouseBillDashboardResponse(
                totalCount,
                openCount,
                overdueCount,
                paidCount,
                normalize(totalAmount),
                normalize(openAmount),
                normalize(overdueAmount),
                normalize(paidAmount)
        );
    }

    private void validateAmount(BigDecimal amount) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new BusinessException("Amount must be greater than zero");
        }
    }

    private RangeFilter resolveRange(LocalDate startDate, LocalDate endDate) {
        if (startDate == null && endDate == null) {
            return new RangeFilter(null, null);
        }

        if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
            throw new BusinessException("End date cannot be before start date");
        }

        return new RangeFilter(startDate, endDate);
    }

    private boolean isWithinRange(HouseBillEntity entity, RangeFilter range) {
        if (range.from() != null && entity.getDueDate().isBefore(range.from())) {
            return false;
        }

        if (range.to() != null && entity.getDueDate().isAfter(range.to())) {
            return false;
        }

        return true;
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

    private BigDecimal sumAmount(List<HouseBillEntity> bills) {
        return bills.stream()
                .map(HouseBillEntity::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private BigDecimal normalize(BigDecimal amount) {
        return amount.setScale(2, RoundingMode.HALF_UP);
    }

    private record RangeFilter(LocalDate from, LocalDate to) {
    }
}
