##############################################################################
# network.tf
# Provisions the Azure Virtual Network, three purpose-specific subnets,
# Network Security Groups, and the private DNS zone for PostgreSQL.
#
# Subnet layout:
#   Public Subnet  (10.0.1.0/24) — Nginx Ingress external load balancer
#   AKS Subnet     (10.0.2.0/24) — AKS node pool (min /24, REQ-2.4)
#   DB Subnet      (10.0.3.0/28) — PostgreSQL Flexible Server (REQ-2.5)
##############################################################################

# ---------------------------------------------------------------------------
# Virtual Network
# ---------------------------------------------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = [var.vnet_address_space]
  tags                = local.common_tags
}

# ---------------------------------------------------------------------------
# Public Subnet — Nginx Ingress / external load balancer
# ---------------------------------------------------------------------------
resource "azurerm_subnet" "public" {
  name                 = "snet-public-${local.name_prefix}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.public_subnet_cidr]
}

# ---------------------------------------------------------------------------
# AKS Subnet — dedicated node pool subnet
# ---------------------------------------------------------------------------
resource "azurerm_subnet" "aks" {
  name                 = "snet-aks-${local.name_prefix}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aks_subnet_cidr]

  # AKS requires ContainerRegistry endpoint for image pulls without stored creds.
  # KeyVault endpoint is required so the Key Vault network ACL can reference this subnet.
  service_endpoints = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault"]
}

# ---------------------------------------------------------------------------
# DB Subnet — PostgreSQL Flexible Server VNet injection
# Delegation to Microsoft.DBforPostgreSQL/flexibleServers is required for
# the Flexible Server to be injected into the VNet (REQ-2.5).
# ---------------------------------------------------------------------------
resource "azurerm_subnet" "db" {
  name                 = "snet-db-${local.name_prefix}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.db_subnet_cidr]

  delegation {
    name = "delegation-postgres-flexibleservers"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# ---------------------------------------------------------------------------
# NSG — Public Subnet
# Permits inbound TCP 80 and 443 from any source; denies all other inbound.
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "public" {
  name                = "nsg-public-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags

  security_rule {
    name                       = "allow-http-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-https-inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-all-other-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}

# ---------------------------------------------------------------------------
# NSG — AKS Subnet
# Denies all inbound traffic from the public internet (REQ-2.2).
# AKS internal communication is handled via VNet routing (allowed by default).
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "aks" {
  name                = "nsg-aks-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags

  security_rule {
    name                       = "deny-internet-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# ---------------------------------------------------------------------------
# NSG — DB Subnet
# Denies all inbound traffic from the public internet (REQ-2.2).
# Only VNet-internal traffic (from AKS pods) can reach PostgreSQL.
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "db" {
  name                = "nsg-db-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags

  security_rule {
    name                       = "deny-internet-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "db" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db.id
}

# ---------------------------------------------------------------------------
# Private DNS Zone — PostgreSQL Flexible Server
# Enables DNS resolution of the Flexible Server hostname to a private VNet IP.
# Required by the Flexible Server VNet injection (REQ-2.3, REQ-5.5).
# ---------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "dns-link-postgres-${local.name_prefix}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  tags                  = local.common_tags
}
