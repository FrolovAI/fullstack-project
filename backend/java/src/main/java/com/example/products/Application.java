package com.example.products;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class Application {
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    @GetMapping("/")
    public String home() {
        return "Java Products Service is running!";
    }
    
    @GetMapping("/health")
    public String health() {
        return "{\"status\": \"healthy\", \"service\": \"java-service\"}";
    }
    
    @GetMapping("/api/products")
    public String products() {
        return "[{\"id\":1,\"name\":\"Test Product\",\"price\":99.99}]";
    }
}
