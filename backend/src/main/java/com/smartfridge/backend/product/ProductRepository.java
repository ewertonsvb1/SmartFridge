package com.smartfridge.backend.product;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface ProductRepository extends JpaRepository<ProductEntity, Long>, JpaSpecificationExecutor<ProductEntity> {

    Optional<ProductEntity> findByIdAndUser_Id(Long id, Long userId);

    List<ProductEntity> findByStatus(ProductStatus status);

    List<ProductEntity> findByExpirationDateLessThanEqual(LocalDate date);

    long countByUser_Id(Long userId);

    long countByUser_IdAndStatus(Long userId, ProductStatus status);
}
