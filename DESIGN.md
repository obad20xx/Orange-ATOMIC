# ATOMIC Tasky — System Architecture & Design Document

This document provides a detailed explanation of the infrastructure, security, networking, and CI/CD architecture of the migrated ATOMIC Tasky application on Microsoft Azure.

---

## 1. High-Level System Architecture

The high-level architecture is designed around containerized microservices running on Azure Kubernetes Service (AKS), a managed PostgreSQL database, and integrated security via Azure Key Vault and Entra ID (OIDC) Workload Identity.

```mermaid
graph TD
    User([User Browser]) -->|"HTTP Port 80"| ALB["Azure Load Balancer"]
    ALB -->|Forward| IngressController["Nginx Ingress Controller"]
    
    subgraph AKS_Cluster ["AKS Cluster (Namespace: production)"]
        IngressController -->|"Route /"| FrontendService["Frontend Service (Port 80)"]
        IngressController -->|"Route /api/*, /swagger-ui, etc."| BackendService["Backend Service (Port 8080)"]
        FrontendService -->|"TargetPort 8080"| FrontendPod["Frontend Pod (Nginx)"]
        FrontendPod -->|"Reverse Proxy /api/*"| BackendService
        BackendService -->|"TargetPort 8080"| BackendPod["Backend Pod (Spring Boot)"]
    end

    subgraph Azure_Managed_Services ["Azure Managed Services"]
        BackendPod -.->|"Azure Workload Identity OIDC"| Entra["Entra ID / Azure AD"]
        Entra -->|"OAuth Token"| KeyVault["Azure Key Vault"]
        BackendPod -->|"Read Secrets"| KeyVault
        BackendPod -->|"JDBC Connection"| Postgres[("PostgreSQL Flexible Server")]
    end
```

### Component Breakdown
1. **Azure Load Balancer (ALB)**: Automatically provisioned by AKS when the Nginx Ingress Controller service is created. It serves as the public entry point for HTTP requests.
2. **Nginx Ingress Controller**: Manages incoming requests. It routes `/` to the Frontend Service and API endpoints (like `/api/*`, `/swagger-ui`, `/infos`, and `/v3/api-docs`) to the Backend Service.
3. **Frontend Pod (Vue 3 + Nginx)**:
   - Runs as a **non-root user** (`UID 101`) on port `8080` to comply with Kubernetes hardening guidelines.
   - Serves static Vue 3 application assets.
   - Contains an internal Nginx reverse-proxy mapping `/api/`, `/swagger-ui`, `/infos`, etc., to the backend pod, avoiding CORS issues by keeping all interactions under a single origin.
4. **Backend Pod (Spring Boot 3.3)**:
   - Runs as a **non-root user** (`UID 10001`) on port `8080`.
   - Uses the Azure SDK to load properties from Key Vault at startup.
   - Connects to the PostgreSQL Database using credentials resolved dynamically.
5. **Azure Key Vault**: Stores the PostgreSQL database password and other runtime secrets. Securely restricts network access using firewall rules (network ACLs).
6. **PostgreSQL Flexible Server**: A managed database instance residing securely inside a dedicated database subnet.

---

## 2. Low-Level Architecture (CI/CD Pipeline)

The CI/CD pipeline is built using Azure Pipelines. It uses a single concurrent agent slot structure, optimized for speed using stage consolidation, BuildKit cache registries, dependency caching, and conditional execution paths for Pull Requests vs. Main Branch Pushes.

```mermaid
graph TD
    Trigger[Commit or PR on Azure branch] --> Stage1[Stage 1: Validate, Lint & Test]
    
    subgraph Stage1_Job ["Stage 1: Validate, Lint & Test (All Runs)"]
        Stage1 --> InstallTools1[Install Terraform & Trivy]
        InstallTools1 --> FormatCheck[Terraform Format Check]
        FormatCheck --> TrivyAudits[Trivy Config Audits: K8s & Terraform]
        TrivyAudits --> RunTests[Parallel Unit Tests: Backend Java & Frontend Vitest]
        RunTests --> PubResults[Publish JUnit Test Results]
    end
    
    PubResults --> Stage2[Stage 2: Infra CD (All Runs)]
    
    subgraph Stage2_Job ["Stage 2: Infra CD (Terraform)"]
        Stage2 --> TFInit[Terraform Init & Plan]
        TFInit --> PRCheck2{Is Pull Request?}
        PRCheck2 -->|Yes| SkipApply[Skip Apply & Outputs]
        PRCheck2 -->|No| TFApply[Terraform Apply & Save Output Variables]
    end
    
    SkipApply --> Stage3[Stage 3: Build & Scan (All Runs)]
    TFApply --> Stage3
    
    subgraph Stage3_Job ["Stage 3: Build & Scan"]
        Stage3 --> ACRLogin[ACR Login & Resolve Server]
        ACRLogin --> BuildImages[Build Docker Images with BuildKit Caching]
        BuildImages --> TrivyScan[Trivy Image Scan Backend & Frontend]
        TrivyScan --> PRCheck3{Is Pull Request?}
        PRCheck3 -->|Yes| SkipPush[Skip Push to ACR]
        PRCheck3 -->|No| PushACR[Push Images to ACR: latest & SHA tags]
        SkipPush --> PubArtifacts[Publish Blueprints Artifact: deployment-assets]
        PushACR --> PubArtifacts
    end
    
    PubArtifacts --> PRCheck4{Is Pull Request?}
    PRCheck4 -->|Yes| EndPR[End Pipeline: PR Validation Success]
    PRCheck4 -->|No| GatedEnv[Stage 4: Deploy - Gated Production Environment Approval]
    
    subgraph Stage4_Job ["Stage 4: Application Deployment"]
        GatedEnv --> DownloadArt[Download Blueprints Artifact]
        DownloadArt --> ConnectAKS[Connect to AKS Cluster using Admin Cert]
        ConnectAKS --> HelmIngress[Ensure Nginx Ingress Controller v4.10.1]
        HelmIngress --> EnvSubst[Compile Manifests via selective envsubst]
        EnvSubst --> KubeApply[Kubectl Apply Manifests]
        KubeApply --> RolloutVerify{Rollout Status Healthy? 8m Timeout}
        RolloutVerify -->|Yes| Live[Live: Print External IP Address]
        RolloutVerify -->|No| RollbackHook[Failure Hook: Trigger Automatic Rollback]
        RollbackHook --> RollbackUndo[Kubectl Rollout Undo Backend/Frontend]
    end
```

### Detailed Pipeline Workflow

#### Stage 1: Validate, Lint & Audit
- **Tool Installation**: Installs Terraform and Trivy on demand.
- **Linting & Security Audits**: Verifies Terraform formatting (`terraform fmt -check`) and audits both Kubernetes manifests and Terraform code using Trivy (`trivy config`).
- **Caching**: Caches the Trivy vulnerability database (`$(HOME)/.cache/trivy`) to minimize scan delays.
- **Backend Tests**: Restores the Gradle dependencies cache (`$(HOME)/.gradle`), installs Java 21, runs Gradle unit tests (`./gradlew test`), and publishes JUnit test results.
- **Frontend Tests**: Restores the npm cache (`$(HOME)/.npm`), installs Node.js 20, installs npm dependencies (`npm ci`), runs Vitest tests (`npx vitest`), and publishes JUnit test results.

#### Stage 2: Infrastructure CD (`InfraCD`)
- **Terraform Run**: Performs `terraform init` using a consolidated Azure backend, followed by `terraform plan`.
- **Conditional Apply**: 
  - **On Pull Requests**: Skips `terraform apply` to allow review of proposed infrastructure plan.
  - **On Direct Pushes (Branch `Azure`)**: Executes `terraform apply -auto-approve` to provision AKS, Database, Key Vault, and ACR.
- **Output Passing**: Captures dynamic outputs (e.g. `AKS_CLUSTER_NAME`, `FLEXIBLE_SERVER_FQDN`, `KEY_VAULT_URI`, `BACKEND_CLIENT_ID`) and converts them into pipeline variables.

#### Stage 3: Build & Package (`Build`)
- **ACR Authentication**: Logs in to Azure Container Registry (ACR). If the ACR has not been fully provisioned (e.g., in a PR dry-run), it resolves/falls back dynamically to query the ACR name.
- **Docker Build (BuildKit)**: Builds frontend and backend Docker containers using Docker BuildKit caching (`--cache-from`) referenced to `:latest` registry tags to accelerate build times.
- **Trivy Image Scan**: Performs pre-push security scans on both backend and frontend images (`trivy image`).
- **Conditional Registry Push**:
  - **On Pull Requests**: Skips pushing the built images to the registry.
  - **On Direct Pushes**: Pushes images to the ACR tagged with the Git commit SHA (`Build.SourceVersion`) and `latest`.
- **Artifact Publishing**: Packs the Kubernetes and Terraform blueprints and publishes them as a pipeline artifact named `deployment-assets`.

#### Stage 4: Deploy & Rollback (`Deploy`)
- **Condition**: Only triggers on direct pushes/commits (skips on PRs) and is gated by the **production** Environment (which requires manual approval gates in Azure DevOps).
- **Cluster Connection**: Downloads the `deployment-assets` artifact and establishes a connection to the AKS cluster using admin credentials.
- **Nginx Ingress**: Installs or upgrades Nginx Ingress Controller (v4.10.1) in the `ingress-nginx` namespace using Helm.
- **Manifest Compilation & Deployment**: Compiles Kubernetes manifests using a selective `envsubst` to inject specific variables (`$ACR_LOGIN_SERVER`, `$IMAGE_TAG`, `$FLEXIBLE_SERVER_FQDN`, `$KEY_VAULT_URI`, `$AZURE_CLIENT_ID`) without corrupting Nginx configurations, and applies them to the cluster.
- **Parallel Health Verification**: Monitors rollout status of both backend and frontend deployments in parallel (8-minute timeout). If both succeed, the ingress public IP is resolved and printed.
- **Automated Rollback**: If any deployment step fails, an Azure Pipelines `on: failure` hook automatically runs `kubectl rollout undo` for both backend and frontend deployments to restore the last stable state.

---

## 3. Security & Networking Architecture

### 3.1 Azure Workload Identity (OIDC)
Instead of storing permanent Azure passwords inside Kubernetes secrets, the Backend pod authenticates via **Azure Workload Identity**:
1. The backend pod is configured with the label `azure.workload.identity/use: "true"`.
2. The AKS mutating admission webhook detects the label and injects an OIDC token volume (`/var/run/secrets/azure/tokens/azure-identity-token`) and environment variables (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_FEDERATED_TOKEN_FILE`).
3. The Spring Boot application presents this OIDC token to Microsoft Entra ID.
4. Entra ID validates the token against the **Federated Identity Credential** linked to the User-Assigned Managed Identity (UAMI) (`uami-atomic-tasky-production-backend`).
5. Entra ID issues an OAuth access token, allowing the backend pod to access the Key Vault and retrieve the database password.

### 3.2 Network Partitioning (Subnets & Private Links)
The Virtual Network (`vnet-atomic-tasky-production`) enforces strict boundaries:
- **Public Subnet (`snet-public...`)**: Hosts the external Load Balancer for the Ingress.
- **AKS Subnet (`snet-aks...`)**: Hosts the AKS virtual machines. Access to the Kubernetes API server is restricted to authorized IPs.
- **Database Subnet (`snet-db...`)**: Delegated exclusively to `Microsoft.DBforPostgreSQL/flexibleServers`.
- **Private DNS Zone**: Resolves the database hostname privately within the VNet. Public access to the database is disabled (`enable_public_access = false`).
- **Key Vault Firewall (Network ACLs)**: The Key Vault default action is set to `Deny`. It only accepts traffic originating from the AKS Subnet and the pipeline agents.
