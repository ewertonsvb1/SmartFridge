package com.smartfridge.backend.product.catalog;

import java.util.Optional;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CatalogProductRepository extends JpaRepository<CatalogProduct, Long> {

    Optional<CatalogProduct> findByNormalizedName(String normalizedName);

    Optional<CatalogProduct> findByBarcode(String barcode);

    boolean existsByNormalizedName(String normalizedName);

    @Query("""
            select c
            from CatalogProduct c
            where c.normalizedName like concat('%', :query, '%')
            order by
                case when c.normalizedName like concat(:query, '%') then 0 else 1 end,
                c.normalizedName asc
            """)
    java.util.List<CatalogProduct> searchOrdered(@Param("query") String query, Pageable pageable);
}
