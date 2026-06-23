##############################################################################
# workload-identity.tf
# Provisions a dedicated User-Assigned Managed Identity for the Backend pod
# and establishes a Federated Identity Credential linking it to the
# Kubernetes ServiceAccount. This enables Azure Workload Identity (OIDC) (REQ-7.5).
##############################################################################

# ---------------------------------------------------------------------------
# User-Assigned Managed Identity for Backend Pod
# ---------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "backend" {
  name                = "uami-${var.project}-${var.environment}-backend"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

# ---------------------------------------------------------------------------
# RBAC: Backend Identity → Key Vault Secrets User (REQ-6.3)
# Grants read/list access on Key Vault secrets to the Backend's User-Assigned
# Managed Identity. This replaces the overly permissive AKS cluster system identity.
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "backend_keyvault_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.backend.principal_id
}

# ---------------------------------------------------------------------------
# Federated Identity Credential
# Establishes the OIDC trust relationship between the AKS cluster's OIDC
# issuer and the Backend User-Assigned Managed Identity.
# Matches namespace "production" and ServiceAccount "backend-workload-identity-sa".
# ---------------------------------------------------------------------------
resource "azurerm_federated_identity_credential" "backend" {
  name                = "fed-${var.project}-${var.environment}-backend"
  resource_group_name = azurerm_resource_group.main.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.main.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.backend.id
  subject             = "system:serviceaccount:production:backend-workload-identity-sa"
}
