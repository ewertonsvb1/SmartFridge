package com.smartfridge.backend.product.nfce;

import com.smartfridge.backend.product.ProductMapper;
import com.smartfridge.backend.product.ProductService;
import com.smartfridge.backend.product.dto.ProductCreateRequest;
import com.smartfridge.backend.product.dto.ProductResponse;
import com.smartfridge.backend.product.nfce.dto.NfceImportConfirmItemRequest;
import com.smartfridge.backend.product.nfce.dto.NfceImportConfirmRequest;
import com.smartfridge.backend.product.nfce.dto.NfceImportConfirmResponse;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class NfceImportConfirmService {

    private final ProductService productService;
    private final ProductMapper productMapper;

    @Transactional
    public NfceImportConfirmResponse confirm(NfceImportConfirmRequest request) {
        List<ProductResponse> createdProducts = request.items().stream()
                .map(this::toCreateRequest)
                .map(productService::create)
                .map(productMapper::toResponse)
                .toList();

        return new NfceImportConfirmResponse(createdProducts.size(), createdProducts);
    }

    private ProductCreateRequest toCreateRequest(NfceImportConfirmItemRequest item) {
        return new ProductCreateRequest(
                item.name(),
                item.quantity(),
                item.manufactureDate(),
                item.expirationDate()
        );
    }
}
