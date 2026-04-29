package com.smartfridge.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class SmartFridgeApplication {

    public static void main(String[] args) {
        SpringApplication.run(SmartFridgeApplication.class, args);
    }
}
