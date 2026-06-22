##############################################################################
# providers.tf
# Declares the required Terraform providers and configures the remote state
# backend using Azure Blob Storage for state locking.
#
# IMPORTANT: The Storage Account, resource group, and container referenced
# here must be created MANUALLY (bootstrap step) before running `terraform init`.
# They are intentionally excluded from this Terraform footprint per REQ-15.4.
##############################################################################

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state backend — Azure Blob Storage with lease-based locking.
  # Values are supplied via the pipeline using -backend-config flags, or
  # via the partial configuration in this block. Operators must ensure the
  # Storage Account and container exist before running `terraform init`.
  backend "azurerm" {
    resource_group_name  = "rg-atomic-tfstate"
    storage_account_name = "atomicterraformstate"
    container_name       = "tfstate"
    key                  = "atomic-tasky.tfstate"

    # State locking is automatic via Azure Blob lease.
    # Blob lease acquisition will be retried up to 3 times with a 5-second
    # interval before returning a non-zero exit code identifying the lock holder.
    # This behavior is built into the azurerm backend and requires no additional config.
  }
}

provider "azurerm" {
  features {
    key_vault {
      # Prevents accidental hard deletion during terraform destroy;
      # soft-deleted vaults can be recovered within the retention period.
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      # Prevents terraform destroy from deleting a resource group that still
      # contains resources not managed by this Terraform footprint.
      prevent_deletion_if_contains_resources = true
    }
  }

  # Authentication is performed by the Azure DevOps Service Connection.
  # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, and ARM_TENANT_ID
  # are injected as environment variables by the pipeline — never hardcoded here.
}

provider "azuread" {
  # Inherits authentication from the ARM_* environment variables set by the
  # Azure DevOps Service Connection, same as the azurerm provider.
}
