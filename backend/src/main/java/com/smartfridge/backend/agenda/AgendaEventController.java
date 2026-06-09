package com.smartfridge.backend.agenda;

import com.smartfridge.backend.agenda.dto.AgendaEventCreateRequest;
import com.smartfridge.backend.agenda.dto.AgendaEventResponse;
import com.smartfridge.backend.agenda.dto.AgendaEventUpdateRequest;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/agenda/events")
@RequiredArgsConstructor
public class AgendaEventController {

    private final AgendaEventService agendaEventService;
    private final AgendaEventMapper agendaEventMapper;

    @PostMapping
    public ResponseEntity<AgendaEventResponse> create(@Valid @RequestBody AgendaEventCreateRequest request) {
        AgendaEventResponse response = agendaEventMapper.toResponse(agendaEventService.create(request));
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<List<AgendaEventResponse>> list(
            @RequestParam(required = false) LocalDate date,
            @RequestParam(required = false) LocalDate startDate,
            @RequestParam(required = false) LocalDate endDate,
            @RequestParam(required = false) AgendaEventStatus status
    ) {
        List<AgendaEventResponse> response = agendaEventService.list(date, startDate, endDate, status).stream()
                .map(agendaEventMapper::toResponse)
                .toList();
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<AgendaEventResponse> getById(@PathVariable Long id) {
        return ResponseEntity.ok(agendaEventMapper.toResponse(agendaEventService.findById(id)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<AgendaEventResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody AgendaEventUpdateRequest request
    ) {
        return ResponseEntity.ok(agendaEventMapper.toResponse(agendaEventService.update(id, request)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        agendaEventService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
