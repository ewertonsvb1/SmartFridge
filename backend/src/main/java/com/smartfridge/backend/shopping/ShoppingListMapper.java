package com.smartfridge.backend.shopping;

import com.smartfridge.backend.shopping.dto.ShoppingListResponse;
import org.springframework.stereotype.Component;

@Component
public class ShoppingListMapper {

    public ShoppingListResponse toResponse(ShoppingListItemEntity item) {
        return new ShoppingListResponse(
                item.getId(),
                item.getName(),
                item.getQuantity(),
                item.isChecked(),
                item.getUser().getId(),
                item.getCreatedAt()
        );
    }
}
