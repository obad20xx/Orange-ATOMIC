##############################################################################
# keyvault.tf
# Provisions Azure Key Vault with soft-delete, network ACLs, and RBAC
# assignment for the AKS Managed Identity (REQ-6).
#
# Key Vault is provisioned BEFORE database.tf because database.tf writes
# the postgres-password secret to this vault during provisioning.
##############################################################################

# Retrieve the current Azure AD client configuration (pipeline Service Principal)
data "azurerm_client_config" "current" {}

# ---------------------------------------------------------------------------
# Azure Key Vault
# Name: max 24 chars, alphanumeric + hyphens, globally unique
# ---------------------------------------------------------------------------
resource "azurerm_key_vault" "main" {
  # Name formula: 'kv-' (3) + project without hyphens (max 10) + hex suffix (6) = max 19 chars
  # e.g. 'kv-atomictasky1a2b3c' — well within the 3-24 char Azure limit.
  name                = "kv-${replace(var.project, "-", "")}${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # Use Azure RBAC for authorization rather than legacy Access Policies
  enable_rbac_authorization = true

  # Tenant ID from the Service Principal used by the pipeline
  tenant_id = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  # Soft-delete configuration: 90-day retention (REQ-6.1)
  soft_delete_retention_days  = var.keyvault_soft_delete_retention_days
  purge_protection_enabled    = true

  # Network ACLs: restrict public access to AKS subnet and pipeline agents.
  # The default action is Deny — only the explicit allow-list can reach Key Vault.
  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"

    # Allow the pipeline agent IP range so Terraform can write secrets
    ip_rules                   = [var.pipeline_agent_ip_range]

    # Allow the AKS subnet so Backend pods can reach Key Vault at runtime
    virtual_network_subnet_ids = [azurerm_subnet.aks.id]
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# RBAC: Pipeline Service Principal → Key Vault Administrator
# Allows Terraform (running as the pipeline Service Principal) to create,
# read, and delete secrets during provisioning.
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "terraform_keyvault_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ---------------------------------------------------------------------------
# RBAC: AKS Managed Identity → Key Vault Secrets User (REQ-6.3)
# Grants the AKS cluster identity read/list access to Key Vault secrets.
# The Backend pod inherits this identity via Workload Identity to fetch
# database credentials at runtime without any stored credentials.
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "aks_keyvault_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id

  depends_on = [azurerm_kubernetes_cluster.main]
}
