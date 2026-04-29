package com.smartfridge.backend.shopping;

import com.smartfridge.backend.common.exception.ResourceNotFoundException;
import com.smartfridge.backend.security.AuthenticatedUserService;
import com.smartfridge.backend.shopping.dto.ShoppingListCreateRequest;
import com.smartfridge.backend.shopping.dto.ShoppingListUpdateRequest;
import com.smartfridge.backend.user.UserEntity;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ShoppingListService {

    private final ShoppingListRepository shoppingListRepository;
    private final AuthenticatedUserService authenticatedUserService;

    @Transactional
    public ShoppingListItemEntity create(ShoppingListCreateRequest request) {
        UserEntity user = authenticatedUserService.getCurrentUser();
        ShoppingListItemEntity item = new ShoppingListItemEntity();
        item.setName(request.name());
        item.setQuantity(request.quantity());
        item.setChecked(false);
        item.setUser(user);
        return shoppingListRepository.save(item);
    }

    @Transactional(readOnly = true)
    public List<ShoppingListItemEntity> list() {
        Long userId = authenticatedUserService.getCurrentUser().getId();
        return shoppingListRepository.findByUser_IdOrderByCreatedAtDesc(userId);
    }

    @Transactional
    public ShoppingListItemEntity update(Long id, ShoppingListUpdateRequest request) {
        Long userId = authenticatedUserService.getCurrentUser().getId();
        ShoppingListItemEntity item = shoppingListRepository.findByIdAndUser_Id(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Shopping item not found"));

        item.setName(request.name());
        item.setQuantity(request.quantity());
        item.setChecked(request.checked());
        return shoppingListRepository.save(item);
    }

    @Transactional
    public void delete(Long id) {
        Long userId = authenticatedUserService.getCurrentUser().getId();
        ShoppingListItemEntity item = shoppingListRepository.findByIdAndUser_Id(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Shopping item not found"));
        shoppingListRepository.delete(item);
    }
}
