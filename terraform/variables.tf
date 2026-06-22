##############################################################################
# variables.tf
# Declares all input variables for the ATOMIC Tasky Azure infrastructure.
# Every variable includes a type constraint and a non-empty description.
# Default values are defined exclusively in terraform.tfvars (REQ-1.3).
##############################################################################

# ---------------------------------------------------------------------------
# Global / Environment
# ---------------------------------------------------------------------------

variable "location" {
  type        = string
  description = "Azure region where all resources will be deployed. Use the Azure region short name, e.g. 'westeurope' or 'northeurope'."
}

variable "environment" {
  type        = string
  description = "Deployment environment label applied as a tag to all resources (e.g. 'production', 'staging'). Used in resource naming conventions."
}

variable "project" {
  type        = string
  description = "Project name label applied as a tag and prefix to all Azure resource names (e.g. 'atomic-tasky')."
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

variable "vnet_address_space" {
  type        = string
  description = "CIDR block for the Azure Virtual Network. Must be at least /16 to contain all subnets (e.g. '10.0.0.0/16')."
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the Public Subnet that hosts the Nginx Ingress external load balancer (e.g. '10.0.1.0/24')."
}

variable "aks_subnet_cidr" {
  type        = string
  description = "CIDR block for the AKS node pool subnet. Must be at least /24 (>=251 usable IPs) to support future scaling (e.g. '10.0.2.0/24')."
}

variable "db_subnet_cidr" {
  type        = string
  description = "CIDR block for the PostgreSQL Flexible Server subnet. Must be at least /28 and delegated to Microsoft.DBforPostgreSQL/flexibleServers (e.g. '10.0.3.0/28')."
}

# ---------------------------------------------------------------------------
# Azure Container Registry
# ---------------------------------------------------------------------------

variable "acr_sku" {
  type        = string
  description = "SKU tier for the Azure Container Registry. Allowed values: 'Basic', 'Standard', 'Premium'. 'Basic' is sufficient for single-cluster pull access."
}

# ---------------------------------------------------------------------------
# AKS Cluster
# ---------------------------------------------------------------------------

variable "aks_kubernetes_version" {
  type        = string
  description = "Pinned Kubernetes minor version for the AKS cluster (e.g. '1.29'). Prevents unplanned upgrades during terraform apply."
}

variable "aks_node_vm_size" {
  type        = string
  description = "VM SKU for the AKS system node pool (e.g. 'Standard_B2s'). Must provide sufficient CPU/memory for Backend + Frontend pods."
}

variable "aks_node_count" {
  type        = number
  description = "Fixed number of nodes in the AKS system node pool. Must be >= 2 for basic availability."
}

# ---------------------------------------------------------------------------
# PostgreSQL Flexible Server
# ---------------------------------------------------------------------------

variable "postgres_sku_name" {
  type        = string
  description = "SKU name for the PostgreSQL Flexible Server in the format 'Tier_Size', e.g. 'B_Standard_B1ms' for Burstable Standard_B1ms."
}

variable "postgres_version" {
  type        = string
  description = "Major PostgreSQL engine version to provision on the Flexible Server (e.g. '16')."
}

variable "postgres_storage_mb" {
  type        = number
  description = "Allocated storage size in megabytes for the PostgreSQL Flexible Server (e.g. 32768 for 32 GiB)."
}

variable "postgres_admin_login" {
  type        = string
  description = "Administrator login username for the PostgreSQL Flexible Server. Must not be 'azure_superuser', 'admin', 'administrator', 'root', 'guest', or 'public'."
}

variable "postgres_db_name" {
  type        = string
  description = "Name of the default database to create on the PostgreSQL Flexible Server (e.g. 'atomicdb')."
}

variable "enable_public_access" {
  type        = bool
  description = "When true, the PostgreSQL Flexible Server also exposes a public endpoint in addition to the private VNet endpoint. Default false (private-only)."
}

# ---------------------------------------------------------------------------
# Azure Key Vault
# ---------------------------------------------------------------------------

variable "keyvault_soft_delete_retention_days" {
  type        = number
  description = "Number of days soft-deleted Key Vault secrets are retained before permanent deletion. Must be between 7 and 90 (e.g. 90)."
}

variable "pipeline_agent_ip_range" {
  type        = string
  description = "Public IP CIDR of the Azure DevOps pipeline agent pool used to allow pipeline access to Key Vault during terraform apply (e.g. '0.0.0.0/0' for Microsoft-hosted agents, or a specific IP range for self-hosted agents)."
}
