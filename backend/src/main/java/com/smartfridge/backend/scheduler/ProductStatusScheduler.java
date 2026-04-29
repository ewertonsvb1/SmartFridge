package com.smartfridge.backend.scheduler;

import com.smartfridge.backend.product.ProductService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class ProductStatusScheduler {

    private final ProductService productService;

    @Scheduled(cron = "0 0 2 * * *")
    public void updateProductStatuses() {
        productService.recalculateAllStatusesAndPrepareLogs();
        log.info("Daily product status recalculation executed");
    }
}
