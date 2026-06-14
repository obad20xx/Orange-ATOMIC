# Backend Architecture & Design Document

## 1. Architectural Overview
The **ATOMIC-Backend** is designed as a robust, resilient, and secure microservice. It is built using **Java 21 LTS** and **Spring Boot 3.3.x**, following strict clean architecture principles. The service enforces a clear separation of concerns across the Domain, Repository, Service, and Controller layers.

## 2. Technology Stack & Rationale
*   **Java 21 LTS:** Chosen for advanced language features and long-term security support.
*   **Spring Boot 3.x:** Provides a modern, cloud-native foundation utilizing Jakarta EE 10.
*   **PostgreSQL:** Relational database providing strong ACID compliance, ideal for tracking state and audit trails of task lifecycles.
*   **HashiCorp Vault:** Integrated via `spring-cloud-starter-vault-config` to enforce a zero-trust architecture. Database credentials are fundamentally decoupled from the application source code and pod environment variables.
*   **Resilience4j:** Protects external integrations (like Vault API polling) preventing cascading system failures via Circuit Breaker patterns.

## 3. Core Components & Layers

### 3.1 Domain Layer (Data Persistence)
The `Task` entity acts as the primary data model, leveraging JPA for persistence. 
*   **Audit Tracking:** Fields like `createdBy` and `lastModifiedBy`, paired with `@CreationTimestamp` and `@UpdateTimestamp`, ensure precise lifecycle tracking.
*   **UUID Identifiers:** Primary keys utilize auto-generated `UUID` strings (`@PrePersist`) to mitigate enumeration attacks and ensure global uniqueness across distributed environments.

### 3.2 Data Transfer Object (DTO) Layer
Internal entities are never exposed directly to the REST interface. Data travels through distinct DTOs (`CreateTaskRequestDto`, `UpdateTaskStatusRequestDto`, `TaskResponseDto`).
*   **Validation boundary:** Jakarta Validation annotations (`@NotBlank`, `@NotNull`) sit squarely at the DTO level to guarantee data sanitation before it enters the business logic layer.

### 3.3 Service Layer (Business Logic)
The `TaskService` governs all database interactions. 
The `VaultService` is specialized for infrastructure auditing. It utilizes Spring 6's modern `RestClient` to query Vault's `/v1/sys/health`.
*   **Circuit Breaker Integration:** Calls to the Vault API are wrapped with `@CircuitBreaker(name = "vault", fallbackMethod = "vaultFallback")`. If Vault becomes unreachable, the backend gracefully degrades, returning a standard fallback payload rather than generating a HTTP 500 error.

### 3.4 Controller Layer (REST Endpoints)
Exposes stateless REST APIs.
*   `/api/tasks`: Handles standard CRUD operations.
*   `/infos`: An auditing endpoint serving active Vault connection status.
*   **Global Exception Handling:** A `@ControllerAdvice` (`GlobalExceptionHandler`) catches invalid payloads (`MethodArgumentNotValidException`) and normalizes them into a clean JSON structure containing exact field errors.

## 4. Security & Configuration Strategy

### 4.1 Vault Secrets Integration (Kubernetes Native)
While local environments utilize `.env` files for ease of setup, the Kubernetes production topology relies heavily on Vault dynamic loading.
1.  During deployment, an `init-vault-secrets` container spins up, checks Vault's readiness, and securely posts the PostgreSQL database credentials into `secret/atomic-backend`.
2.  The backend pod boots with `VAULT_ENABLED=true`.
3.  Spring Cloud Vault automatically intercepts the boot sequence, authenticates with the internal Vault server, and resolves `spring.datasource.username` and `password`. The main backend container environment variables remain completely clean of database credentials.

### 4.2 Endpoint Security
*   **Stateless Execution:** `SessionCreationPolicy.STATELESS` ensures complete REST compliance without maintaining server-side memory for sessions.
*   **CORS Management:** Strict CORS configurations allow only specified frontend origins (passed dynamically via the `CORS_ALLOWED_ORIGINS` environment variable) to communicate with the APIs.

## 5. Testing & Quality Assurance
The application leverages Spring Boot Test strategies paired with an in-memory `H2` database for rapid execution.
*   **Integration Tests:** `TaskApiTests` utilizes `MockMvc` to send precise HTTP payloads and assert exact JSON outputs using `jsonPath`. This guarantees the API contract between the frontend and backend remains unbroken during future refactoring.
