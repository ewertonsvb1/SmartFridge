package com.smartfridge.backend.product;

import com.smartfridge.backend.product.dto.ProductCreateRequest;
import com.smartfridge.backend.product.dto.ProductDashboardResponse;
import com.smartfridge.backend.product.dto.ProductResponse;
import com.smartfridge.backend.product.dto.ProductUpdateRequest;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/products")
@RequiredArgsConstructor
public class ProductController {

    private final ProductService productService;
    private final ProductMapper productMapper;

    @PostMapping
    public ResponseEntity<ProductResponse> create(@Valid @RequestBody ProductCreateRequest request) {
        ProductResponse response = productMapper.toResponse(productService.create(request));
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<Page<ProductResponse>> list(
            @RequestParam(required = false) String name,
            @RequestParam(required = false) ProductStatus status,
            Pageable pageable
    ) {
        Page<ProductResponse> page = productService.findAll(name, status, pageable).map(productMapper::toResponse);
        return ResponseEntity.ok(page);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ProductResponse> getById(@PathVariable Long id) {
        return ResponseEntity.ok(productMapper.toResponse(productService.findById(id)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ProductResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody ProductUpdateRequest request
    ) {
        return ResponseEntity.ok(productMapper.toResponse(productService.update(id, request)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        productService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/expired")
    public ResponseEntity<List<ProductResponse>> expired() {
        return ResponseEntity.ok(productService.expired().stream().map(productMapper::toResponse).toList());
    }

    @GetMapping("/expiring")
    public ResponseEntity<List<ProductResponse>> expiring(@RequestParam(defaultValue = "3") int days) {
        return ResponseEntity.ok(productService.expiring(days).stream().map(productMapper::toResponse).toList());
    }

    @GetMapping("/dashboard")
    public ResponseEntity<ProductDashboardResponse> dashboard() {
        return ResponseEntity.ok(productService.dashboard());
    }
}
