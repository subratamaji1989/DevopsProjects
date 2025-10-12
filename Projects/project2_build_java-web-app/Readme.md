# Developing and Deploying a Java Web App with VS Code

This guide provides a complete playbook for developing, containerizing, and deploying a Java Spring Boot web application using Visual Studio Code, Docker, and Kubernetes on a local Windows machine.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Create and Run the Java App in VS Code](#part-1-create-and-run-the-java-app-in-vs-code)

---

## Prerequisites

Before you begin, ensure you have the following installed and configured:

1.  **Visual Studio Code**: The code editor.
2.  **Extension Pack for Java**: The essential VS Code extension for Java development. It includes:
    *   Language Support for Java™ by Red Hat
    *   Debugger for Java
    *   Test Runner for Java
    *   Maven for Java
    *   Project Manager for Java
3.  **Spring Boot Extension Pack**: This extension pack simplifies Spring Boot development in VS Code.
4.  **JDK 17+**: An installed Java Development Kit. We recommend [Eclipse Temurin](https://adoptium.net/).
5.  **Docker Desktop for Windows**:
    *   Ensure it's configured to use the **WSL 2 based engine**.
    *   Enable Kubernetes by going to **Settings > Kubernetes > Enable Kubernetes**.

---

## Part 1: Create and Run the Java App in VS Code

### Step 1: Create a New Spring Boot Project

We will use the Spring Initializr extension integrated into VS Code.

1.  Open the Command Palette (`Ctrl+Shift+P`).
2.  Type `Spring Initializr` and select **Spring Initializr: Create a Maven Project...**.
3.  Follow the prompts:
    *   **Spring Boot Version**: Select a stable version (e.g., 3.2.x).
    *   **Language**: `Java`.
    *   **Group Id**: e.g., `com.example`.
    *   **Artifact Id**: e.g., `java-web-app`.
    *   **Packaging Type**: `Jar`.
    *   **Java Version**: `17` (or your installed JDK version).
    *   **Dependencies**: Search for and select:
        *   `Spring Web`: For building web applications.
        *   `Spring Boot Actuator`: For health checks and monitoring.
4.  Select a folder to generate the project into. VS Code will create the project and ask if you want to open it. Click **Open**.

### Step 2: Run and Debug the Application

The Java extensions make it easy to run and debug your application directly within the editor.

1.  Open the main application file: `src/main/java/com/example/javawebapp/JavaWebAppApplication.java`.
2.  You will see `Run` and `Debug` links above the `main` method.
3.  Click **Run** to start the application.
4.  Open the **TERMINAL** panel to see the Spring Boot application logs.
5.  Once started, you can access the health endpoint at `http://localhost:8080/actuator/health` in your browser.
6.  To stop the application, click the red square on the floating debug toolbar or press `Ctrl+C` in the terminal.

