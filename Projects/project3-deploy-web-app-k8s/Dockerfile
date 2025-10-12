# # ----------------------------------------------------
# # Stage 1: Build the application with Maven
# # ----------------------------------------------------
# FROM maven:3.9.6-eclipse-temurin-17 AS build
# ----------------------------------------------------# ARG MAVEN_OPTS="-Xmx1024m"
# ENV MAVEN_OPTS=${MAVEN_OPTS}

# # Set working directory
# WORKDIR /app

# # Cache dependencies to speed up builds
# COPY pom.xml .
# RUN mvn dependency:go-offline
# Cache dependencies to speed
# # Copy source and build application
# COPY src ./src
# RUN mvn clean package -DskipTests
# Copy source and build application
# COPY src ./src

# ----------------------------------------------------
# Stage 2: Runtime (minimal, secure, non-root)
# ----------------------------------------------------
FROM gcr.io/distroless/java17:nonroot

WORKDIR /app

# Copy the built JAR from the build stage
# COPY --from=build /app/target/*.jar app.jar
COPY target/*.jar app.jar

# Default environment variables
ENV APP_ENV=production \
    JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom" \
    APP_URL="http://localhost:8080"

# Expose application port
EXPOSE 8080

# Health check (example: Spring Boot actuator or simple HTTP check)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080"] || exit 1

# Run as non-root user (distroless nonroot user is already configured)
USER nonroot:nonroot

# Default labels
LABEL maintainer="Your Name <you@example.com>" \
      org.opencontainers.image.title="Java Maven App" \
      org.opencontainers.image.description="Secure, minimal, non-root Java application container" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.licenses="MIT"

# Default command
ENTRYPOINT ["java", "-jar", "app.jar"]
