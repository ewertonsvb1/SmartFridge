package com.smartfridge.backend.housebill;

import com.smartfridge.backend.housebill.dto.HouseBillCreateRequest;
import com.smartfridge.backend.housebill.dto.HouseBillDashboardResponse;
import com.smartfridge.backend.housebill.dto.HouseBillResponse;
import com.smartfridge.backend.housebill.dto.HouseBillUpdateRequest;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/house-bills")
@RequiredArgsConstructor
public class HouseBillController {

    private final HouseBillService houseBillService;
    private final HouseBillMapper houseBillMapper;

    @PostMapping
    public ResponseEntity<HouseBillResponse> create(@Valid @RequestBody HouseBillCreateRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(houseBillMapper.toResponse(houseBillService.create(request)));
    }

    @GetMapping
    public ResponseEntity<List<HouseBillResponse>> list(
            @RequestParam(required = false) HouseBillStatus status,
            @RequestParam(required = false) LocalDate startDate,
            @RequestParam(required = false) LocalDate endDate
    ) {
        return ResponseEntity.ok(houseBillService.list(status, startDate, endDate).stream()
                .map(houseBillMapper::toResponse)
                .toList());
    }

    @GetMapping("/{id}")
    public ResponseEntity<HouseBillResponse> getById(@PathVariable Long id) {
        return ResponseEntity.ok(houseBillMapper.toResponse(houseBillService.findById(id)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<HouseBillResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody HouseBillUpdateRequest request
    ) {
        return ResponseEntity.ok(houseBillMapper.toResponse(houseBillService.update(id, request)));
    }

    @PatchMapping("/{id}/payment")
    public ResponseEntity<HouseBillResponse> markAsPaid(@PathVariable Long id) {
        return ResponseEntity.ok(houseBillMapper.toResponse(houseBillService.markAsPaid(id)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        houseBillService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/dashboard")
    public ResponseEntity<HouseBillDashboardResponse> dashboard(
            @RequestParam(required = false) LocalDate startDate,
            @RequestParam(required = false) LocalDate endDate
    ) {
        return ResponseEntity.ok(houseBillService.dashboard(startDate, endDate));
    }
}
