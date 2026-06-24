# ⚛ ATOMIC Tasky — Enterprise Software Architecture & Implementation

[![Azure Pipelines](https://img.shields.io/badge/Azure_Pipelines-Secured-blue?logo=azure-pipelines&style=flat-square)](https://dev.azure.com)
[![Azure AKS](https://img.shields.io/badge/Kubernetes-Azure_AKS-blue?logo=kubernetes&style=flat-square)](https://azure.microsoft.com/products/kubernetes-service/)
[![Helm](https://img.shields.io/badge/Helm-v3-blue?logo=helm&style=flat-square)](https://helm.sh)
[![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.x-brightgreen?logo=springboot&style=flat-square)](https://spring.io/projects/spring-boot)
[![Vue 3](https://img.shields.io/badge/Vue.js-3.x-green?logo=vue.js&style=flat-square)](https://vuejs.org/)
[![Azure Key Vault](https://img.shields.io/badge/Azure_Key_Vault-Secured-blue?logo=azure&style=flat-square)](https://azure.microsoft.com/services/key-vault/)

Welcome to the **ATOMIC Tasky** project. This repository contains a production-ready, cloud-native Task Management application engineered with a high-performance **Spring Boot 3** backend and a reactive, modern **Vue 3** frontend. The infrastructure is orchestrated using **Terraform** and **Kubernetes manifests**, and fully automated via an **Azure DevOps** pipeline, target-deploying directly to an **Azure Kubernetes Service (AKS)** cluster.

---

## 📋 Executive Summary & Architectural Decisions

**ATOMIC Tasky** was designed to demonstrate senior-level software engineering, system design, and platform architecture. The system prioritizes strict separation of concerns, enterprise-grade security, fault tolerance, and comprehensive environment portability.

For detailed diagrams and analysis of the high-level and low-level system layouts, see:
👉 **[System Architecture & Design Document (DESIGN.md)](DESIGN.md)**

### 1. Application Layer Choices
*   **Backend (Spring Boot 3 + Java 21):** Leveraging JDK 21 capabilities, Spring Boot 3 provides a robust, REST-compliant framework. Spring Data JPA acts as an abstraction over PostgreSQL. The controller layer implements strict validation (`Jakarta Validation`) to ensure data sanitization at the API boundary before hitting business logic.
*   **Frontend (Vue 3 + Vite):** Structured as a lightweight Single Page Application (SPA). To optimize network traffic and simplify deployment, Vite builds the source code into highly optimized static assets, which are then served directly by an enterprise-hardened, non-root **Nginx** container.

### 2. Security & Zero-Trust Infrastructure
*   **Azure Workload Identity Integration:** Database credentials and other sensitive configurations are never hardcoded or injected directly via container environment variables. The system uses **Azure Workload Identity (OIDC)** to securely link the Kubernetes ServiceAccount to a User-Assigned Managed Identity (UAMI). The Spring Boot backend leverages `spring-cloud-azure-starter-keyvault-secrets` to fetch secrets dynamically from **Azure Key Vault** at boot time.
*   **Privilege Minimization:** All containers run as strict **non-root** system users (`UID 10001` in the backend, `UID 101` in the frontend).
*   **Kubernetes Security Contexts:** Restrict privilege escalation, block root execution, and enforce read-only root filesystems where applicable.

### 3. Traffic Routing & CORS Mitigation
*   **Nginx Single-Domain Proxy Strategy:** Rather than exposing the Spring Boot API directly to the public internet and dealing with complex, brittle CORS configuration, Nginx serves as a **Reverse Proxy**. 
    *   Requests to the frontend root (`/`) serve static UI assets on a non-privileged port (`8080`).
    *   Requests prefixed with `/api/` or `/infos` are proxy-passed internally to the backend service via cluster-internal DNS.
    *   This completely eliminates CORS issues because the client only ever communicates with a single domain/port.

### 4. Fault Tolerance & Observability
*   **Resilience4j Circuit Breaker:** Implemented on the `GET /infos` endpoint. If Key Vault goes offline or database connections fail, the circuit transitions seamlessly. A custom fallback handler intercepts the error, prevents a cascading `500 Internal Server Error`, and returns a graceful, degraded status payload to the Vue UI.
*   **Health Checks & Probes:** Integrated Spring Boot Actuator endpoints (`/actuator/health`) directly map to Kubernetes `livenessProbe` and `readinessProbe` to guarantee self-healing cluster capabilities.

---

## ⚡ Local Rapid-Setup (Docker Compose)

You can launch the complete ecosystem locally with a single command. The Docker Compose configuration establishes explicit dependency chains, ensuring the database and local HashiCorp Vault container are fully operational before bootstrapping the backend.

### 1. Frictionless Zero-Configuration Launch
Run the following command at the root of the project to build and spin up the stack:
```bash
docker compose up -d --build
```

### 2. Initialize Vault Secret Values
To simulate production secret fetching locally, Vault must be populated with database credentials. Run the pre-written script based on your shell:

**PowerShell (Windows):**
```powershell
./ATOMIC-Backend/scripts/setup-vault-secrets.ps1
```

**Bash (Linux/WSL2/macOS):**
```bash
VAULT_URI="http://localhost:8200"
VAULT_TOKEN="dev-only-root-token"
curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST \
     --data '{"data": {"spring.datasource.username": "atomic_user", "spring.datasource.password": "change_me"}}' \
     $VAULT_URI/v1/secret/data/atomic-backend
```

### 3. Local Entrypoints
*   **Web Dashboard UI:** [http://localhost:3000](http://localhost:3000)
*   **Spring Boot Swagger UI:** [http://localhost:8080/swagger-ui.html](http://localhost:8080/swagger-ui.html)
*   **HashiCorp Vault UI:** [http://localhost:8200](http://localhost:8200) (Token: `dev-only-root-token`)

---

## 🚀 Azure DevOps CI/CD Automation Pipeline

The project utilizes a fully automated, production-grade `azure-pipelines.yml` pipeline split into four highly optimized stages.

### Stage 1: Validate, Lint & Audit
*   Runs `terraform fmt -check` to verify Terraform format.
*   Runs **Trivy** config scans on Kubernetes manifests and Terraform files to audit configurations.
*   Runs Backend unit tests (Gradle) and Frontend tests (Vitest) in parallel, utilizing cached gradle/npm directories.

### Stage 2: Infrastructure CD (`InfraCD`)
*   Unified Terraform stage to provision ACR, AKS, Key Vault, and PostgreSQL Flexible Server inside a secure VNet.
*   Generates a `terraform plan` on Pull Requests, and automatically executes `terraform apply` on direct merges to the `Azure` branch.

### Stage 3: Build & Package (`Build`)
*   Authenticates to the Azure Container Registry (ACR).
*   Builds Backend and Frontend Docker images utilizing BuildKit caching (`--cache-from`) to pull unchanged layers from ACR, reducing build times.
*   Scans the built images using **Trivy** for vulnerabilities before pushing them to ACR.
*   Publishes Kubernetes and Terraform blueprints as a Pipeline Artifact `deployment-assets`.

### Stage 4: Deploy & Verify (`Deploy`)
*   Downloads the `deployment-assets` blueprint.
*   Connects to the AKS cluster and ensures the Ingress Nginx Controller is ready via Helm.
*   Compiles the Kubernetes blueprints using `envsubst` with specific pipeline variables to prevent Nginx config corruption.
*   Applies the resources and verifies the rollout status (`kubectl rollout status`).
*   **Auto-Rollback on Failure**: If health checks fail, the pipeline automatically triggers a rollback (`kubectl rollout undo`) to restore the last stable deployment version.

---

## 🛠 Operations Guide & Handover Runbook

### 1. Accessing the Cluster via `kubectl`
To connect to the AKS cluster manually, run the following command on your local machine:
```powershell
az aks get-credentials --resource-group ERAMOVA --name aks-atomic-tasky-production --admin --overwrite-existing
```

### 2. Checking System Status
```bash
# Check all resources inside the production namespace
kubectl get all -n production

# Stream backend live logs
kubectl logs -f deployment/backend -n production

# Stream frontend live logs
kubectl logs -f deployment/frontend -n production
```

### 3. Handling Rollbacks manually
If you ever need to manually revert a deployment to its previous version:
```bash
kubectl rollout undo deployment/backend -n production
kubectl rollout undo deployment/frontend -n production
```

---

## 💎 Verification & Definition of Done
- [x] **Spring Boot API endpoints** (`GET /infos`, `/api/tasks`) respond with correct payloads and audit tracking.
- [x] **Vue 3 UI components** handle active loading states, error fallbacks, and audit badges seamlessly.
- [x] **Docker Compose configuration** establishes high cohesion and launches the local stack sequentially.
- [x] **Azure DevOps pipeline** validates configurations, provisions infrastructure, builds production containers with layer caching, and automates deployments.
- [x] **AKS Cluster** routes traffic through Nginx Ingress, resolves the PostgreSQL database via Private DNS, and fetches Key Vault secrets securely using OIDC Workload Identity.
