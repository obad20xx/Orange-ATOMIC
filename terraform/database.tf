##############################################################################
# database.tf
# Provisions Azure Database for PostgreSQL Flexible Server inside the DB
# subnet and writes the administrator password to Key Vault (REQ-5).
#
# Execution order enforced via explicit depends_on:
#   1. Key Vault must exist before this module runs (to store the password)
#   2. Private DNS zone and VNet link must exist before the server (VNet injection)
##############################################################################

# ---------------------------------------------------------------------------
# Random password for the PostgreSQL administrator
# A new password is generated on first apply and stored permanently in Key Vault.
# ---------------------------------------------------------------------------
resource "random_password" "postgres_admin" {
  length           = 32
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

# ---------------------------------------------------------------------------
# Store PostgreSQL password in Key Vault immediately after generation (REQ-5.4, REQ-6.2)
# If this write fails, terraform apply returns a non-zero exit code and
# the Flexible Server resource will not be created (depends_on chain).
# ---------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-password"
  value        = random_password.postgres_admin.result
  key_vault_id = azurerm_key_vault.main.id

  content_type = "text/plain"

  tags = local.common_tags

  # Must wait for the Key Vault and the Terraform admin role assignment
  depends_on = [
    azurerm_key_vault.main,
    azurerm_role_assignment.terraform_keyvault_admin,
  ]
}

# ---------------------------------------------------------------------------
# PostgreSQL Flexible Server
# SKU: Burstable / Standard_B1ms (REQ-5.1)
# VNet injection into DB Subnet via private DNS zone (REQ-5.2, REQ-2.3)
# ---------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server" "main" {
  name                = "psql-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # Compute tier and SKU (REQ-5.1)
  sku_name = var.postgres_sku_name

  # Engine version (REQ-5)
  version = var.postgres_version

  # Storage
  storage_mb = var.postgres_storage_mb

  # Administrator credentials
  administrator_login    = var.postgres_admin_login
  administrator_password = random_password.postgres_admin.result

  # VNet integration — inject the server into the DB subnet (REQ-5.2)
  # Requires the subnet delegation and private DNS zone to exist first.
  delegated_subnet_id = azurerm_subnet.db.id
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id

  # Public access control (REQ-5.3):
  #   - enable_public_access = false (default) → private VNet only
  #   - enable_public_access = true → adds a public endpoint alongside VNet access
  public_network_access_enabled = var.enable_public_access

  # Note: high_availability is intentionally omitted.
  # The Burstable compute tier (Standard_B1ms) does not support any HA mode.
  # ZoneRedundant and SameZone HA require GeneralPurpose or MemoryOptimized tiers.

  # Backup retention
  backup_retention_days = 7

  tags = local.common_tags

  # VNet integration must be complete before the server starts (REQ-5.2)
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres,
    azurerm_key_vault_secret.postgres_password,
  ]

  lifecycle {
    ignore_changes = [
      zone,
    ]
  }
}

# ---------------------------------------------------------------------------
# Default database "atomicdb" (REQ-5.4)
# ---------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_database" "atomicdb" {
  name      = var.postgres_db_name
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}
