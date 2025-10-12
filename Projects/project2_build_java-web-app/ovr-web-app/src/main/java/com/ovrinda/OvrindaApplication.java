package com.ovrinda;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * The main entry point for the Spring Boot application.
 * This class uses the @SpringBootApplication annotation, which is a convenience
 * annotation that adds:
 * - @Configuration: Tags the class as a source of bean definitions for the application context.
 * - @EnableAutoConfiguration: Tells Spring Boot to start adding beans based on classpath settings.
 * - @ComponentScan: Tells Spring to look for other components, configurations, and services in the 'com.example' package.
 */
@SpringBootApplication
public class OvrindaApplication {

    public static void main(String[] args) {
        // Launches the application. The embedded Tomcat server starts automatically here.
        SpringApplication.run(OvrindaApplication.class, args);
    }

}
