package com.smartfridge.backend.product;

import com.smartfridge.backend.product.dto.ProductResponse;
import org.springframework.stereotype.Component;

@Component
public class ProductMapper {

    public ProductResponse toResponse(ProductEntity product) {
        return new ProductResponse(
                product.getId(),
                product.getName(),
                product.getQuantity(),
                product.getManufactureDate(),
                product.getExpirationDate(),
                product.getStatus(),
                product.getUser().getId(),
                product.getCreatedAt()
        );
    }
}
