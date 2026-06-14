# ⚛ ATOMIC Tasky — Enterprise Software Architecture & Implementation

[![GitLab CI/CD](https://img.shields.io/badge/GitLab-CI%2FCD-orange?logo=gitlab&style=flat-square)](https://gitlab.com)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-DigitalOcean-blue?logo=kubernetes&style=flat-square)](https://www.digitalocean.com/products/kubernetes/)
[![Helm](https://img.shields.io/badge/Helm-v3-blue?logo=helm&style=flat-square)](https://helm.sh)
[![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.x-brightgreen?logo=springboot&style=flat-square)](https://spring.io/projects/spring-boot)
[![Vue 3](https://img.shields.io/badge/Vue.js-3.x-green?logo=vue.js&style=flat-square)](https://vuejs.org/)
[![HashiCorp Vault](https://img.shields.io/badge/HashiCorp_Vault-Secured-black?logo=hashicorp&style=flat-square)](https://www.vaultproject.io/)

Welcome to the **ATOMIC Tasky** project. This repository contains a production-ready, cloud-native Task Management application engineered with a high-performance **Spring Boot 3** backend and a reactive, modern **Vue 3** frontend. The infrastructure is orchestrated using **Helm v3** and fully automated via a **GitLab CI/CD** pipeline, target-deploying directly to a **DigitalOcean Kubernetes (DOKS)** cluster.

---

## 📋 Executive Summary & Architectural Decisions

**ATOMIC Tasky** was designed to demonstrate senior-level software engineering, system design, and platform architecture. The system prioritizes strict separation of concerns, enterprise-grade security, fault tolerance, and comprehensive environment portability.

### 1. Application Layer Choices
*   **Backend (Spring Boot 3 + Java 21):** Leveraging JDK 21 capabilities (including optimizations for modern workloads), Spring Boot 3 provides a robust, REST-compliant framework. Spring Data JPA acts as an abstraction over PostgreSQL. The controller layer implements strict validation (`Jakarta Validation`) to ensure data sanitization at the API boundary before hitting business logic.
*   **Frontend (Vue 3 + Vite):** Structured as a lightweight Single Page Application (SPA). To optimize network traffic and simplify deployment, Vite builds the source code into highly optimized static assets, which are then served directly by an enterprise-hardened **Nginx** container.

### 2. Security & Zero-Trust Infrastructure
*   **HashiCorp Vault Integration:** Database credentials and other sensitive configurations are never hardcoded or injected directly via container environment variables. The Kubernetes deployment utilizes an `init-vault-secrets` container to securely provision Vault, and the Spring Boot backend leverages `Spring Cloud Vault` to fetch secrets dynamically at boot time.
*   **Privilege Minimization:** All containers run as strict **non-root** system users (`taskyuser` in the backend, custom Nginx user limits on the frontend).
*   **Kubernetes Security Contexts:** Restrict privilege escalation, block root execution, and enforce read-only root filesystems where applicable.

### 3. Traffic Routing & CORS Mitigation
*   **Nginx Single-Domain Proxy Strategy:** Rather than exposing the Spring Boot API directly to the public internet and dealing with complex, brittle CORS configuration, Nginx serves as a **Reverse Proxy**. 
    *   Requests to the frontend root (`/`) serve static UI assets.
    *   Requests prefixed with `/api/` or `/infos` are proxy-passed internally to the backend service via cluster-internal DNS.
    *   This completely eliminates CORS issues because the client only ever communicates with a single domain/port.

### 4. Fault Tolerance & Observability
*   **Resilience4j Circuit Breaker:** Implemented on the `GET /infos` endpoint. If HashiCorp Vault goes offline or undergoes maintenance, the circuit transitions seamlessly. A custom fallback handler intercepts the error, prevents a cascading `500 Internal Server Error`, and returns a graceful, degraded status payload to the Vue UI.
*   **Health Checks & Probes:** Integrated Spring Boot Actuator endpoints (`/actuator/health`) directly map to Kubernetes `livenessProbe` and `readinessProbe` to guarantee self-healing cluster capabilities.

---

## 🗺 System Architecture & Network Topologies

This project operates on a **fully automated, cloud-hosted production architecture on DigitalOcean Kubernetes (DOKS)**, accessible directly via a dedicated DigitalOcean Load Balancer IP. A local Docker Compose environment is also maintained for rapid edge development.

### Production Cloud Deployment (DigitalOcean Kubernetes)
Deployed automatically via the GitLab CI/CD runner. Traffic enters over HTTP directly targeting the DigitalOcean Load Balancer IP.

```text
               [ Public Client Request ]
                          │
                          ▼ (HTTP - Port 80)
            [ DigitalOcean Cloud Load Balancer ]
                    (143.244.196.81)
                          │
                          ▼ (Enters Namespace: "production")
             [ tasky-frontend Service (LoadBalancer) ]
                          │
       ┌──────────────────┴──────────────────────────────────────────┐
       │                                                             │
       ▼ (Serves Static files)                                       ▼ (Proxy-Pass /api/)
[ tasky-frontend Pods (Nginx) ]                             [ tasky-backend Pods (Spring Boot) ]
                                                                     │
                                      ┌──────────────────────────────┼──────────────────────────────┐
                                      ▼ (Port 5432)                  ▼ (Port 8200)                  ▼ (Port 8080)
                         [ postgresql-primary (StatefulSet) ]  [ orange-atomic-vault ]    [ /actuator/health ]
                                                               (Dynamic Secret Fetch)      (Kubernetes Probes)
```

---

## ⚡ Local Rapid-Setup (Docker Compose)

You can launch the complete ecosystem locally with a single command. The Docker Compose configuration establishes explicit dependency chains, ensuring the database and Vault containers are fully operational before bootstrapping the backend.

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

## 🎡 Helm Chart Configuration & K8s Hardening

The Kubernetes manifests are unified into a single modular Helm chart: `helm/tasky-app`. 

### Chart Architecture & Dependencies
The chart utilizes official enterprise sub-charts dynamically managed via `Chart.yaml`:
*   `postgresql` (Bitnami)
*   `vault` (Official HashiCorp)

### Production Values Configuration (`values.yaml`)
Our production deployment strictly overrides chart values to ensure defense-in-depth:
1.  **Security Context Hardening:** Enforces `runAsNonRoot: true` and `runAsUser: 10001` on the backend deployment.
2.  **Resource Allocation Limits:** Explicit CPU/Memory limits and requests prevent noisy-neighbor issues on shared cluster nodes.
3.  **Self-Healing Probes Configuration:** `initialDelaySeconds: 65` is declared on the liveness probe to allow the JVM to complete class loading and bootstrap safely.

---

## 🚀 GitLab CI/CD Automation Pipeline

The project utilizes a fully automated, state-of-the-art `.gitlab-ci.yml` pipeline split into three highly optimized stages.

### Stage 1: Build Backend (`build-backend`)
*   **Action:** Runs a Docker build using the multi-stage `ATOMIC-Backend/Dockerfile`.
    *   *Stage 1:* Spins up `gradle:8.7-jdk21-alpine`, caches dependencies, and compiles the bootable `.jar`.
    *   *Stage 2:* Extracts the artifact into an `eclipse-temurin:21-jre-alpine` runtime and hardens the container privileges.
*   **Outcome:** Pushes the versioned tag (`$CI_COMMIT_SHORT_SHA`) to the GitLab Container Registry.

### Stage 2: Build Frontend (`build-frontend`)
*   **Action:** Builds the Vue 3 dashboard using `ATOMIC-Frontend/Dockerfile`.
    *   *Static injection:* Injects `VITE_API_BASE_URL=/` during build. This forces the UI client to route API calls directly back to Nginx (securing communication under a single domain).
*   **Outcome:** Pushes the frontend container to the GitLab Container Registry.

### Stage 3: Cloud Deployment (`deploy-to-do-k8s`)
*   **Execution Flow:**
    1.  Decodes `$KUBECONFIG_BASE64` into the CI runner to safely authenticate against the DigitalOcean K8s Cluster.
    2.  Creates a persistent Kubernetes secret (`regcred`) using a GitLab Deploy Token to pull private registry images securely.
    3.  Runs `helm upgrade --install` with dynamic parameter injection.
    4.  Waits for K8s deployments and StatefulSets to report healthy.
    5.  Outputs the secure live production URL pointing directly to the Load Balancer IP.

---

## 🛠 Operations Guide & Handover Runbook

### 1. Accessing the Live Production Environment
The application is fully operational and deployed in production. It can be accessed directly at the DigitalOcean Load Balancer static IP:
👉 **[http://143.244.196.81/](http://143.244.196.81/)**

### 2. Checking System Status via `kubectl`
```bash
# Check all resources inside the production namespace
kubectl get all -n production

# Stream backend live logs
kubectl logs -f deployment/orange-atomic-backend -n production -c backend
```

### 3. Handling Database Backups
To run a database dump directly from the active PostgreSQL StatefulSet pod:
```bash
kubectl exec -it orange-atomic-postgresql-0 -n production -- \
  pg_dump -U atomic_user -d atomic_db > backup.sql
```

### 4. Troubleshooting Vault Dynamics
If the Vault service is uninitialized or falls back to degraded status:
1.  Check the Vault service logs:
    ```bash
    kubectl logs -f deployment/orange-atomic-backend -n production -c init-vault-secrets
    ```
2.  If Vault restarted and requires unsealing, enter the container directly:
    ```bash
    kubectl exec -it orange-atomic-vault-0 -n production -- vault operator unseal <your-unseal-key>
    ```

---

## 💎 Verification & Definition of Done
- [x] **Spring Boot API endpoints** (`GET /infos`, `/api/tasks`) respond with correct payloads and audit tracking.
- [x] **Vue 3 UI components** handle active loading states, error fallbacks, and audit badges seamlessly.
- [x] **Docker Compose configuration** establishes high cohesion and launches the local stack sequentially.
- [x] **Helm chart v3 template** correctly deploys the Vue frontend, Spring Boot backend, Bitnami PostgreSQL, and Vault.
- [x] **GitLab CI/CD automated pipeline** performs verification, builds production images, and executes zero-downtime rolling upgrades.
- [x] **DigitalOcean Kubernetes cluster** auto-provisions load-balancer IP `143.244.196.81` and secures production access.
