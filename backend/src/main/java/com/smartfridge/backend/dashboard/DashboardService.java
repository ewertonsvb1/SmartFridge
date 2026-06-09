package com.smartfridge.backend.dashboard;

import com.smartfridge.backend.agenda.AgendaEventEntity;
import com.smartfridge.backend.agenda.AgendaEventService;
import com.smartfridge.backend.dashboard.dto.AgendaDashboardResponse;
import com.smartfridge.backend.dashboard.dto.DashboardResponse;
import com.smartfridge.backend.dashboard.dto.FridgeDashboardResponse;
import com.smartfridge.backend.dashboard.dto.HouseBillsDashboardResponse;
import com.smartfridge.backend.housebill.HouseBillService;
import com.smartfridge.backend.housebill.dto.HouseBillDashboardResponse;
import com.smartfridge.backend.product.ProductService;
import com.smartfridge.backend.product.dto.ProductDashboardResponse;
import java.time.LocalDate;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final ProductService productService;
    private final AgendaEventService agendaEventService;
    private final HouseBillService houseBillService;

    @Transactional(readOnly = true)
    public DashboardResponse getDashboard() {
        LocalDate today = LocalDate.now();
        ProductDashboardResponse productDashboard = productService.dashboard();
        List<AgendaEventEntity> agendaEvents = agendaEventService.list(null, null, null, null);
        long agendaToday = agendaEvents.stream()
                .filter(event -> event.getStartAt().toLocalDate().isEqual(today))
                .count();
        long agendaUpcoming = agendaEvents.stream()
                .filter(event -> event.getStartAt().toLocalDate().isAfter(today))
                .count();
        HouseBillDashboardResponse houseBillDashboard = houseBillService.dashboard(null, null);

        return new DashboardResponse(
                new FridgeDashboardResponse(
                        productDashboard.total(),
                        productDashboard.expired(),
                        productDashboard.nearExpiration()
                ),
                new AgendaDashboardResponse(true, agendaEvents.size(), agendaToday, agendaUpcoming),
                new HouseBillsDashboardResponse(
                        true,
                        houseBillDashboard.openCount(),
                        houseBillDashboard.overdueCount(),
                        houseBillDashboard.paidCount()
                )
        );
    }
}
