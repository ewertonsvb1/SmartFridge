package com.smartfridge.backend.database;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import javax.sql.DataSource;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(properties = {
        "DB_URL=jdbc:h2:mem:migrationtest;MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE",
        "DB_USER=sa",
        "DB_PASS=",
        "JWT_SECRET=test-only-secret-with-at-least-32-chars",
        "CORS_ALLOWED_ORIGINS=https://smartfridge-backend-c27p.onrender.com",
        "spring.datasource.driver-class-name=org.h2.Driver"
})
@ActiveProfiles("prod")
class DatabaseMigrationTest {

    @Autowired
    private DataSource dataSource;

    @Test
    void shouldBootstrapSchemaWithFlywayBeforeHibernateValidation() {
        JdbcTemplate jdbcTemplate = new JdbcTemplate(dataSource);

        assertThat(tableExists(jdbcTemplate, "flyway_schema_history")).isTrue();
        assertThat(tableExists(jdbcTemplate, "USERS")).isTrue();
        assertThat(tableExists(jdbcTemplate, "PRODUCTS")).isTrue();
        assertThat(tableExists(jdbcTemplate, "SHOPPING_LIST_ITEMS")).isTrue();
        assertThat(tableExists(jdbcTemplate, "NOTIFICATION_LOGS")).isTrue();
        assertThat(tableExists(jdbcTemplate, "AGENDA_EVENTS")).isTrue();
        assertThat(tableExists(jdbcTemplate, "HOUSE_BILLS")).isTrue();

        Integer appliedVersions = jdbcTemplate.queryForObject(
                "select count(*) from \"flyway_schema_history\" where \"success\" = true and \"version\" = '1'",
                Integer.class);

        assertThat(appliedVersions).isEqualTo(1);
    }

    private boolean tableExists(JdbcTemplate jdbcTemplate, String tableName) {
        try (Connection connection = jdbcTemplate.getDataSource().getConnection();
             ResultSet exact = connection.getMetaData().getTables(null, null, tableName, new String[]{"TABLE"})) {
            if (exact.next()) {
                return true;
            }
        } catch (SQLException exception) {
            throw new IllegalStateException("Failed to inspect table metadata for " + tableName, exception);
        }

        try (Connection connection = jdbcTemplate.getDataSource().getConnection();
             ResultSet lower = connection.getMetaData().getTables(null, null, tableName.toLowerCase(), new String[]{"TABLE"})) {
            if (lower.next()) {
                return true;
            }
        } catch (SQLException exception) {
            throw new IllegalStateException("Failed to inspect table metadata for " + tableName, exception);
        }

        try (Connection connection = jdbcTemplate.getDataSource().getConnection();
             ResultSet upper = connection.getMetaData().getTables(null, null, tableName.toUpperCase(), new String[]{"TABLE"})) {
            return upper.next();
        } catch (SQLException exception) {
            throw new IllegalStateException("Failed to inspect table metadata for " + tableName, exception);
        }
    }
}
