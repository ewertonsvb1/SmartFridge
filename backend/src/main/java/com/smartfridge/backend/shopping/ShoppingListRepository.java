package com.smartfridge.backend.shopping;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ShoppingListRepository extends JpaRepository<ShoppingListItemEntity, Long> {

    List<ShoppingListItemEntity> findByUser_IdOrderByCreatedAtDesc(Long userId);

    Optional<ShoppingListItemEntity> findByIdAndUser_Id(Long id, Long userId);
}
