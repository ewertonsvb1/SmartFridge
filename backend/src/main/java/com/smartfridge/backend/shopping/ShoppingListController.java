package com.smartfridge.backend.shopping;

import com.smartfridge.backend.shopping.dto.ShoppingListCreateRequest;
import com.smartfridge.backend.shopping.dto.ShoppingListResponse;
import com.smartfridge.backend.shopping.dto.ShoppingListUpdateRequest;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/shopping-list")
@RequiredArgsConstructor
public class ShoppingListController {

    private final ShoppingListService shoppingListService;
    private final ShoppingListMapper shoppingListMapper;

    @PostMapping
    public ResponseEntity<ShoppingListResponse> create(@Valid @RequestBody ShoppingListCreateRequest request) {
        ShoppingListResponse response = shoppingListMapper.toResponse(shoppingListService.create(request));
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<List<ShoppingListResponse>> list() {
        return ResponseEntity.ok(shoppingListService.list().stream().map(shoppingListMapper::toResponse).toList());
    }

    @PutMapping("/{id}")
    public ResponseEntity<ShoppingListResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody ShoppingListUpdateRequest request
    ) {
        return ResponseEntity.ok(shoppingListMapper.toResponse(shoppingListService.update(id, request)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        shoppingListService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
