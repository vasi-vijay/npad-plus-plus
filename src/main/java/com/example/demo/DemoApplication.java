package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

/**
 * CodePad++ for Mac (Apple Silicon) - Java & Spring Boot Toolkit
 * Native performance on M1, M2, M3, M4 Apple Silicon architectures.
 */
@SpringBootApplication
@RestController
@RequestMapping("/api/v1/notepad")
public class DemoApplication {

    public static void main(String[] args) {
        System.out.println("Starting CodePad++ Spring Boot Backend on macOS ARM64...");
        SpringApplication.run(DemoApplication.class, args);
    }

    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getSystemStatus() {
        return ResponseEntity.ok(Map.of(
            "status", "UP",
            "arch", "aarch64 / arm64",
            "runtime", "Apple Silicon Optimized",
            "editor", "CodePad++ for Mac",
            "javaVersion", System.getProperty("java.version", "21")
        ));
    }

    @GetMapping("/features")
    public ResponseEntity<List<String>> listFeatures() {
        return ResponseEntity.ok(List.of(
            "Ultra-fast native Apple Silicon rendering",
            "Multi-document tabs with unsaved change tracking",
            "Regex Find & Replace with Mark Lines",
            "Integrated Developer Terminal with zsh / bash",
            "Git status, branch, and line diffs",
            "Spring Boot & Java symbol navigation",
            "Modular plugin architecture with JSON and Base64 tools"
        ));
    }
}
