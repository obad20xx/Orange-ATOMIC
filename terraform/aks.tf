##############################################################################
# aks.tf
# Provisions the Azure Kubernetes Service cluster with:
#   - System node pool: Standard_B2s, 2 nodes
#   - System-assigned Managed Identity
#   - Azure RBAC for Kubernetes API authorization
#   - OIDC issuer and Workload Identity enabled for pod-level AAD auth
#   - Pinned Kubernetes version
#   - Node pool placed in the AKS subnet (REQ-4)
##############################################################################

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # Pin the Kubernetes minor version to prevent unplanned upgrades (REQ-4.7)
  kubernetes_version = var.aks_kubernetes_version

  # The DNS prefix must be unique within the Azure region
  dns_prefix = "${local.name_prefix}-k8s"

  # ---------------------------------------------------------------------------
  # Default (System) Node Pool
  # Standard_B2s: 2 vCPU, 4 GiB RAM — cost-appropriate for this workload.
  # Fixed node count of 2 for basic availability (REQ-4.1).
  # ---------------------------------------------------------------------------
  default_node_pool {
    name                = "systempool"
    node_count          = var.aks_node_count
    vm_size             = var.aks_node_vm_size
    vnet_subnet_id      = azurerm_subnet.aks.id
    os_disk_size_gb     = 30
    type                = "VirtualMachineScaleSets"

    # Disable auto-scaling to maintain fixed node count
    enable_auto_scaling = false

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
    }

    upgrade_settings {
      max_surge = "10%"
    }
  }

  # ---------------------------------------------------------------------------
  # Identity — System-assigned Managed Identity (REQ-4.3)
  # Enables AKS components (kubelet, agentpool) to authenticate to Azure
  # services (ACR, Key Vault) without stored credentials.
  # ---------------------------------------------------------------------------
  identity {
    type = "SystemAssigned"
  }

  # ---------------------------------------------------------------------------
  # Azure RBAC — Kubernetes API access governed by Azure AD roles (REQ-4.2)
  # ---------------------------------------------------------------------------
  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  # ---------------------------------------------------------------------------
  # OIDC Issuer + Workload Identity (REQ-4.5)
  # Required for pod-level Azure AD federated credential authentication,
  # which allows the Backend pod to obtain tokens for Key Vault access
  # without any stored secrets.
  # ---------------------------------------------------------------------------
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # ---------------------------------------------------------------------------
  # Network profile — Azure CNI for VNet-integrated pods
  # ---------------------------------------------------------------------------
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  tags = local.common_tags

  lifecycle {
    # Prevent accidental kubernetes_version downgrade
    ignore_changes = [
      kubernetes_version,
      default_node_pool[0].node_count,
    ]
  }
}

# ---------------------------------------------------------------------------
# Role Assignment: AKS Managed Identity → Network Contributor on AKS subnet
# Required so AKS can manage load balancer resources in the subnet.
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_subnet.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}
