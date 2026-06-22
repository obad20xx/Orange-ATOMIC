##############################################################################
# main.tf
# Root composition module — creates the Azure Resource Group and applies
# common tags used by all downstream resources. All resource modules reference
# the resource group created here via data sources or direct references.
##############################################################################

locals {
  # Naming prefix applied to all Azure resources for easy identification
  name_prefix = "${var.project}-${var.environment}"

  # Common tags propagated to all Azure resources in this footprint
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "Orange-ATOMIC"
  }
}

##############################################################################
# Resource Group
# Single resource group for all ATOMIC Tasky Azure resources.
# The Terraform state backend Storage Account is NOT in this resource group.
##############################################################################
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}

##############################################################################
# Random suffix for globally unique resource names (ACR, Key Vault)
# Azure Container Registry names must be globally unique and alphanumeric only.
# Key Vault names must be globally unique and 3–24 characters.
##############################################################################
resource "random_id" "suffix" {
  byte_length = 3
}
