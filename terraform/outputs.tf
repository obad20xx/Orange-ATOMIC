##############################################################################
# outputs.tf
# Exports key resource attributes consumed by the Azure Pipelines pipeline
# (ACR login server, AKS cluster name, resource group, PostgreSQL FQDN).
# The pipeline uses `terraform output -raw <name>` to read these values.
##############################################################################

# ---------------------------------------------------------------------------
# Azure Container Registry
# ---------------------------------------------------------------------------
output "acr_login_server" {
  description = "The login server URL of the Azure Container Registry. Used by the pipeline to tag and push Docker images (e.g. 'acratomictasky1a2b.azurecr.io')."
  value       = azurerm_container_registry.main.login_server
}

output "acr_name" {
  description = "The name of the Azure Container Registry resource."
  value       = azurerm_container_registry.main.name
}

# ---------------------------------------------------------------------------
# AKS Cluster
# ---------------------------------------------------------------------------
output "aks_cluster_name" {
  description = "The name of the AKS cluster. Used by the pipeline in `az aks get-credentials --name <aks_cluster_name>`."
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_oidc_issuer_url" {
  description = "The OIDC issuer URL of the AKS cluster. Used to configure Federated Identity Credentials for Workload Identity."
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------
output "resource_group_name" {
  description = "The name of the Azure Resource Group containing all ATOMIC Tasky resources."
  value       = azurerm_resource_group.main.name
}

# ---------------------------------------------------------------------------
# PostgreSQL Flexible Server
# ---------------------------------------------------------------------------
output "flexible_server_fqdn" {
  description = "The fully-qualified domain name of the PostgreSQL Flexible Server (e.g. 'psql-atomic-tasky-production.postgres.database.azure.com'). Used in the Backend ConfigMap SPRING_DATASOURCE_URL."
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

# ---------------------------------------------------------------------------
# Azure Key Vault
# ---------------------------------------------------------------------------
output "key_vault_uri" {
  description = "The URI of the Azure Key Vault (e.g. 'https://kvatomictasky1a2b.vault.azure.net/'). Injected into the Backend pod as AZURE_KEYVAULT_URI."
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_name" {
  description = "The name of the Azure Key Vault resource."
  value       = azurerm_key_vault.main.name
}

# ---------------------------------------------------------------------------
# Backend Workload Identity
# ---------------------------------------------------------------------------
output "backend_identity_client_id" {
  description = "The client ID of the User-Assigned Managed Identity for the backend. Injected into the Kubernetes ServiceAccount."
  value       = azurerm_user_assigned_identity.backend.client_id
}

