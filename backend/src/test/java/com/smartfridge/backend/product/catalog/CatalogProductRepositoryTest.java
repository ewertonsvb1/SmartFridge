package com.smartfridge.backend.product.catalog;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.dao.DataIntegrityViolationException;

@DataJpaTest
class CatalogProductRepositoryTest {

    @Autowired
    private CatalogProductRepository repository;

    @Test
    void shouldPersistCatalogProductWithPreparedOptionalFields() {
        CatalogProduct product = new CatalogProduct();
        product.setName("Leite Italac");
        product.setNormalizedName("leite italac");

        CatalogProduct saved = repository.saveAndFlush(product);

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(saved.getUpdatedAt()).isNotNull();
        assertThat(saved.getBrand()).isNull();
        assertThat(saved.getCategory()).isNull();
        assertThat(saved.getBarcode()).isNull();
    }

    @Test
    void shouldFindProductByNormalizedName() {
        CatalogProduct product = new CatalogProduct();
        product.setName("Leite Italac");
        product.setNormalizedName("leite italac");
        product.setBarcode("7896004400912");
        repository.saveAndFlush(product);

        var found = repository.findByNormalizedName("leite italac");

        assertThat(found).isPresent();
        assertThat(found.get().getName()).isEqualTo("Leite Italac");
        assertThat(repository.findByBarcode("7896004400912")).isPresent();
    }

    @Test
    void shouldRejectDuplicateNormalizedName() {
        CatalogProduct first = new CatalogProduct();
        first.setName("Leite Italac");
        first.setNormalizedName("leite italac");
        repository.saveAndFlush(first);

        CatalogProduct duplicate = new CatalogProduct();
        duplicate.setName("Leité  Italác");
        duplicate.setNormalizedName("leite italac");

        assertThrows(DataIntegrityViolationException.class, () -> repository.saveAndFlush(duplicate));
    }

    @Test
    void shouldRejectDuplicateBarcode() {
        CatalogProduct first = new CatalogProduct();
        first.setName("Leite Italac");
        first.setNormalizedName("leite italac");
        first.setBarcode("7896004400912");
        repository.saveAndFlush(first);

        CatalogProduct duplicate = new CatalogProduct();
        duplicate.setName("Leite Piracanjuba");
        duplicate.setNormalizedName("leite piracanjuba");
        duplicate.setBarcode("7896004400912");

        assertThrows(DataIntegrityViolationException.class, () -> repository.saveAndFlush(duplicate));
    }
}
