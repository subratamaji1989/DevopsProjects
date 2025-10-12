# Local Development Environment Setup on Windows

This guide provides a complete, step-by-step playbook for setting up a robust local development environment on a Windows machine. It uses WSL2, Docker Desktop, and Kubernetes to create a local cloud-native environment suitable for general application development and MLOps.

## Table of Contents
1. [Part 1: One-Time Infrastructure Setup](#part-1-one-time-infrastructure-setup)
   - [Security Best Practices](#security-best-practices)
2. [Part 2: Example - Deploying a Java Application](#part-2-example---deploying-a-java-application)
   - [Troubleshooting Common Issues](#troubleshooting-common-issues)
3. [Part 3: Advanced - Local MLOps Setup](#part-3-advanced---local-mlops-setup)

---

## Part 2: Example - Deploying a Java Application

This section walks through building a container image for a Java application and deploying it to your local Kubernetes cluster.

### Step 1: Build the Java Application

1.  Navigate to your Spring Boot project's root directory.
2.  Build the executable JAR file using Maven or Gradle.
    ```bash
    # Using Maven
    mvn clean package -DskipTests

    # Using Gradle
    ./gradlew bootJar
    ```
    This will typically create a JAR file in the `target/` or `build/libs/` directory.

### Step 2: Create a Dockerfile

Create a file named `Dockerfile` in your project's root directory. This multi-stage `Dockerfile` first builds the application inside a container and then copies the final JAR to a smaller runtime image.

```dockerfile
# ----------------------------------------------------
# Stage 1: Build the application with Maven
# ----------------------------------------------------
FROM maven:3.9.6-eclipse-temurin-17 AS build

# Set build arguments
ARG MAVEN_OPTS="-Xmx1024m"
ENV MAVEN_OPTS=${MAVEN_OPTS}

# Set working directory
WORKDIR /app

# Cache dependencies to speed up builds
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy source and build application
COPY src ./src
RUN mvn clean package -DskipTests

# ----------------------------------------------------
# Stage 2: Runtime (minimal, secure, non-root)
# ----------------------------------------------------
FROM gcr.io/distroless/java17:nonroot

# Set working directory
WORKDIR /app

# Copy the built JAR from the build stage
COPY --from=build /app/target/*.jar app.jar

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
```

### Step 3: Build the Docker Image

Build the image and tag it. The local Kubernetes cluster will be able to use this image directly.

```bash
docker build -t ovr-web-app-image:v1 .
```

### Step 4: Create Kubernetes Manifests

Create a file named `k8s-manifests.yaml`. This file defines a `Deployment` to run your application and a `Service` to expose it.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: java-app-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: java-app
  template:
    metadata:
      labels:
        app: java-app
    spec:
      containers:
      - name: java-app
        image: java-app-local:v1
        imagePullPolicy: IfNotPresent # Crucial for using local images
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 20
---
apiVersion: v1
kind: Service
metadata:
  name: java-app-service
spec:
  type: NodePort # Exposes the service on the host machine's network
  selector:
    app: java-app # Must match the labels in the Deployment template
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
```

### Step 5: Deploy and Access the Application

1.  **Apply the Manifests**:
    ```bash
    kubectl apply -f k8s-manifests.yaml
    ```

2.  **Check Pod Status**:
    Watch the pods until they are in the `Running` state.
    ```bash
    kubectl get pods --watch
    ```

3.  **Find the Service Port (`NodePort`)**:
    Get the details of the service to find the port it's exposed on.
    ```bash
    kubectl get svc java-app-service
    ```
    The output will look like this. The `NodePort` is the number after the colon (e.g., `31234`).
    ```
    NAME               TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
    java-app-service   NodePort   10.104.2.208   <none>        8080:31234/TCP   1m
    ```

4.  **Access the Application**:
    Open your web browser and navigate to `http://localhost:<NodePort>`. For example: `http://localhost:31234`. If your app has a health check endpoint, you can test it at `http://localhost:31234/actuator/health`.

### Step 6: Cleanup

To remove the application from your cluster, delete the resources.

```bash
kubectl delete -f k8s-manifests.yaml
```

---
