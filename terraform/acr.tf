##############################################################################
# acr.tf
# Provisions the Azure Container Registry (ACR) and assigns the AcrPull role
# to the AKS cluster's Managed Identity so nodes can pull images without
# storing registry credentials as Kubernetes Secrets (REQ-3).
##############################################################################

# ---------------------------------------------------------------------------
# Azure Container Registry
# Name must be globally unique, alphanumeric only, 5–50 characters.
# random_id.suffix ensures global uniqueness.
# ---------------------------------------------------------------------------
resource "azurerm_container_registry" "main" {
  name                = "acr${replace(local.name_prefix, "-", "")}${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = false # Admin account disabled; AKS uses Managed Identity pull

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# AcrPull Role Assignment — AKS Managed Identity → ACR
# Grants the AKS kubelet Managed Identity the AcrPull built-in role scoped
# to the ACR resource, enabling image pulls without stored credentials.
# This resource has an explicit dependency on both AKS and ACR.
# If ACR provisioning fails, terraform apply fails before this role is created.
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id

  depends_on = [
    azurerm_container_registry.main,
    azurerm_kubernetes_cluster.main,
  ]
}
