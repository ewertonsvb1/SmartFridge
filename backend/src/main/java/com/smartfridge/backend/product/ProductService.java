package com.smartfridge.backend.product;

import com.smartfridge.backend.common.exception.BusinessException;
import com.smartfridge.backend.common.exception.ResourceNotFoundException;
import com.smartfridge.backend.notification.NotificationLogService;
import com.smartfridge.backend.notification.NotificationType;
import com.smartfridge.backend.product.dto.ProductCreateRequest;
import com.smartfridge.backend.product.dto.ProductDashboardResponse;
import com.smartfridge.backend.product.dto.ProductUpdateRequest;
import com.smartfridge.backend.security.AuthenticatedUserService;
import com.smartfridge.backend.user.UserEntity;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ProductService {

    private static final long NEAR_EXPIRATION_DAYS = 3;

    private final ProductRepository productRepository;
    private final AuthenticatedUserService authenticatedUserService;
    private final NotificationLogService notificationLogService;

    @Transactional
    public ProductEntity create(ProductCreateRequest request) {
        validateDates(request.manufactureDate(), request.expirationDate());
        UserEntity currentUser = authenticatedUserService.getCurrentUser();

        ProductEntity entity = new ProductEntity();
        entity.setName(request.name());
        entity.setQuantity(request.quantity());
        entity.setManufactureDate(request.manufactureDate());
        entity.setExpirationDate(request.expirationDate());
        entity.setUser(currentUser);
        entity.setStatus(calculateStatus(request.expirationDate()));

        ProductEntity saved = productRepository.save(entity);
        createNotificationIfNeeded(saved);
        return saved;
    }

    @Transactional(readOnly = true)
    public Page<ProductEntity> findAll(String name, ProductStatus status, Pageable pageable) {
        Long userId = authenticatedUserService.getCurrentUser().getId();
        Specification<ProductEntity> spec = ProductSpecification.belongsToUser(userId);

        if (name != null && !name.isBlank()) {
            spec = spec.and(ProductSpecification.withName(name));
        }
        if (status != null) {
            spec = spec.and(ProductSpecification.withStatus(status));
        }

        return productRepository.findAll(spec, pageable);
    }

    @Transactional(readOnly = true)
    public ProductEntity findById(Long id) {
        Long userId = authenticatedUserService.getCurrentUser().getId();
        return productRepository.findByIdAndUser_Id(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Product not found"));
    }

    @Transactional
    public ProductEntity update(Long id, ProductUpdateRequest request) {
        validateDates(request.manufactureDate(), request.expirationDate());
        ProductEntity entity = findById(id);

        entity.setName(request.name());
        entity.setQuantity(request.quantity());
        entity.setManufactureDate(request.manufactureDate());
        entity.setExpirationDate(request.expirationDate());
        entity.setStatus(calculateStatus(request.expirationDate()));

        ProductEntity saved = productRepository.save(entity);
        createNotificationIfNeeded(saved);
        return saved;
    }

    @Transactional
    public void delete(Long id) {
        ProductEntity entity = findById(id);
        productRepository.delete(entity);
    }

    @Transactional(readOnly = true)
    public List<ProductEntity> expired() {
        Long userId = authenticatedUserService.getCurrentUser().getId();
        return productRepository.findAll(
                ProductSpecification.belongsToUser(userId)
                        .and(ProductSpecification.withStatus(ProductStatus.EXPIRED))
        );
    }

    @Transactional(readOnly = true)
    public List<ProductEntity> expiring(int days) {
        Long userId = authenticatedUserService.getCurrentUser().getId();
        LocalDate now = LocalDate.now();
        LocalDate limit = now.plusDays(days);

        return productRepository.findAll((root, query, cb) -> cb.and(
                cb.equal(root.get("user").get("id"), userId),
                cb.greaterThan(root.get("expirationDate"), now.minusDays(1)),
                cb.lessThanOrEqualTo(root.get("expirationDate"), limit)
        ));
    }

    @Transactional(readOnly = true)
    public ProductDashboardResponse dashboard() {
        Long userId = authenticatedUserService.getCurrentUser().getId();
        long total = productRepository.countByUser_Id(userId);
        long expired = productRepository.countByUser_IdAndStatus(userId, ProductStatus.EXPIRED);
        long near = productRepository.countByUser_IdAndStatus(userId, ProductStatus.NEAR_EXPIRATION);
        return new ProductDashboardResponse(total, expired, near);
    }

    @Transactional
    public void recalculateAllStatusesAndPrepareLogs() {
        List<ProductEntity> products = productRepository.findAll();
        for (ProductEntity product : products) {
            ProductStatus recalculated = calculateStatus(product.getExpirationDate());
            if (product.getStatus() != recalculated) {
                product.setStatus(recalculated);
            }
            createNotificationIfNeeded(product);
        }
        productRepository.saveAll(products);
    }

    private void validateDates(LocalDate manufactureDate, LocalDate expirationDate) {
        if (expirationDate.isBefore(manufactureDate)) {
            throw new BusinessException("Expiration date cannot be before manufacture date");
        }
    }

    public ProductStatus calculateStatus(LocalDate expirationDate) {
        LocalDate now = LocalDate.now();
        if (expirationDate.isBefore(now)) {
            return ProductStatus.EXPIRED;
        }

        long days = ChronoUnit.DAYS.between(now, expirationDate);
        if (days <= NEAR_EXPIRATION_DAYS) {
            return ProductStatus.NEAR_EXPIRATION;
        }

        return ProductStatus.OK;
    }

    private void createNotificationIfNeeded(ProductEntity product) {
        if (product.getStatus() == ProductStatus.EXPIRED) {
            notificationLogService.registerIfNotExists(product, NotificationType.EXPIRED);
        } else if (product.getStatus() == ProductStatus.NEAR_EXPIRATION) {
            notificationLogService.registerIfNotExists(product, NotificationType.NEAR_EXPIRATION);
        }
    }
}
