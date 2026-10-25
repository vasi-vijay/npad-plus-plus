import { TabItem } from '../types';

export const INITIAL_TABS: TabItem[] = [
  {
    id: 'tab-java-1',
    title: 'DemoApplication.java',
    path: 'src/main/java/com/example/demo/DemoApplication.java',
    language: 'java',
    encoding: 'UTF-8',
    lineEnding: 'LF',
    bookmarks: [14, 28],
    cursorLine: 1,
    cursorCol: 1,
    selectionStart: 0,
    selectionEnd: 0,
    isModified: false,
    savedContent: `package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

/**
 * Notepad++ for Mac (Apple Silicon) - Java & Spring Boot Toolkit
 * Native performance on M1, M2, M3, M4 Apple Silicon architectures.
 */
@SpringBootApplication
@RestController
@RequestMapping("/api/v1/notepad")
public class DemoApplication {

    public static void main(String[] args) {
        System.out.println("Starting Notepad++ Spring Boot Backend on macOS ARM64...");
        SpringApplication.run(DemoApplication.class, args);
    }

    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getSystemStatus() {
        return ResponseEntity.ok(Map.of(
            "status", "UP",
            "arch", "aarch64 / arm64",
            "runtime", "Apple Silicon Optimized",
            "editor", "Notepad++ for Mac",
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
`,
    content: `package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

/**
 * Notepad++ for Mac (Apple Silicon) - Java & Spring Boot Toolkit
 * Native performance on M1, M2, M3, M4 Apple Silicon architectures.
 */
@SpringBootApplication
@RestController
@RequestMapping("/api/v1/notepad")
public class DemoApplication {

    public static void main(String[] args) {
        System.out.println("Starting Notepad++ Spring Boot Backend on macOS ARM64...");
        SpringApplication.run(DemoApplication.class, args);
    }

    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getSystemStatus() {
        return ResponseEntity.ok(Map.of(
            "status", "UP",
            "arch", "aarch64 / arm64",
            "runtime", "Apple Silicon Optimized",
            "editor", "Notepad++ for Mac",
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
`,
  },
  {
    id: 'tab-swift-2',
    title: 'NotepadPlusApp.swift',
    path: 'macos-app/Sources/NotepadPlusMac/NotepadPlusApp.swift',
    language: 'swift',
    encoding: 'UTF-8',
    lineEnding: 'LF',
    bookmarks: [],
    cursorLine: 1,
    cursorCol: 1,
    selectionStart: 0,
    selectionEnd: 0,
    isModified: false,
    savedContent: `import SwiftUI
import AppKit

// Target: macOS 14 Sonoma / macOS 15 Sequoia (Apple Silicon ARM64)
@main
struct NotepadPlusApp: App {
    @StateObject private var appState = AppStateManager()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(appState)
                .frame(minWidth: 960, minHeight: 640)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
    }
}
`,
    content: `import SwiftUI
import AppKit

// Target: macOS 14 Sonoma / macOS 15 Sequoia (Apple Silicon ARM64)
@main
struct NotepadPlusApp: App {
    @StateObject private var appState = AppStateManager()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(appState)
                .frame(minWidth: 960, minHeight: 640)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
    }
}
`,
  },
  {
    id: 'tab-props-3',
    title: 'application.properties',
    path: 'src/main/resources/application.properties',
    language: 'properties',
    encoding: 'UTF-8',
    lineEnding: 'LF',
    bookmarks: [],
    cursorLine: 1,
    cursorCol: 1,
    selectionStart: 0,
    selectionEnd: 0,
    isModified: false,
    savedContent: `# Spring Boot Configuration for Notepad++ Mac Environment
server.port=8080
spring.application.name=notepad-mac-developer-suite

# Database Configuration
spring.datasource.url=jdbc:postgresql://localhost:5432/notepad_db
spring.datasource.username=postgres
spring.datasource.password=password
spring.jpa.hibernate.ddl-auto=update

# Logging Configuration
logging.level.root=INFO
logging.level.com.example.demo=DEBUG
logging.pattern.console=%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n
`,
    content: `# Spring Boot Configuration for Notepad++ Mac Environment
server.port=8080
spring.application.name=notepad-mac-developer-suite

# Database Configuration
spring.datasource.url=jdbc:postgresql://localhost:5432/notepad_db
spring.datasource.username=postgres
spring.datasource.password=password
spring.jpa.hibernate.ddl-auto=update

# Logging Configuration
logging.level.root=INFO
logging.level.com.example.demo=DEBUG
logging.pattern.console=%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n
`,
  },
  {
    id: 'tab-pom-4',
    title: 'pom.xml',
    path: 'pom.xml',
    language: 'xml',
    encoding: 'UTF-8',
    lineEnding: 'LF',
    bookmarks: [],
    cursorLine: 1,
    cursorCol: 1,
    selectionStart: 0,
    selectionEnd: 0,
    isModified: false,
    savedContent: `<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>notepad-spring-app</artifactId>
    <version>1.0.0</version>
    <name>Notepad++ Spring Developer Backend</name>
    <properties>
        <java.version>21</java.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
            <version>3.2.2</version>
        </dependency>
    </dependencies>
</project>
`,
    content: `<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>notepad-spring-app</artifactId>
    <version>1.0.0</version>
    <name>Notepad++ Spring Developer Backend</name>
    <properties>
        <java.version>21</java.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
            <version>3.2.2</version>
        </dependency>
    </dependencies>
</project>
`,
  },
];
