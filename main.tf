terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.5.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Resource group
resource "azurerm_resource_group" "postgres_rg" {
  name     = "postgres-resources"
  location = "East US"
}

# Virtual Network
resource "azurerm_virtual_network" "postgres_vnet" {
  name                = "postgres-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.postgres_rg.location
  resource_group_name = azurerm_resource_group.postgres_rg.name
}

# Subnet for the PostgreSQL Server
resource "azurerm_subnet" "postgres_subnet" {
  name                 = "postgres-subnet"
  resource_group_name  = azurerm_resource_group.postgres_rg.name
  virtual_network_name = azurerm_virtual_network.postgres_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Sql"]
}

# PostgreSQL Server
resource "azurerm_postgresql_server" "postgres_server" {
  name                = "postgres-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  location            = azurerm_resource_group.postgres_rg.location
  resource_group_name = azurerm_resource_group.postgres_rg.name

  sku_name = "GP_Gen5_2" # General Purpose, Gen 5, 2 vCores

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  administrator_login          = "psqladmin"
  administrator_login_password = "P@ssw0rd1234!"

  version                 = "11"
  ssl_enforcement_enabled = true
}

# PostgreSQL Database
resource "azurerm_postgresql_database" "postgres_db" {
  name                = "exampledb"
  resource_group_name = azurerm_resource_group.postgres_rg.name
  server_name         = azurerm_postgresql_server.postgres_server.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

# Configure firewall rules
resource "azurerm_postgresql_firewall_rule" "postgres_rule" {
  name                = "allow-azure-internal"
  resource_group_name = azurerm_resource_group.postgres_rg.name
  server_name         = azurerm_postgresql_server.postgres_server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Optional: VNet rule for more secure access
resource "azurerm_postgresql_virtual_network_rule" "postgres_vnet_rule" {
  name                = "postgres-vnet-rule"
  resource_group_name = azurerm_resource_group.postgres_rg.name
  server_name         = azurerm_postgresql_server.postgres_server.name
  subnet_id           = azurerm_subnet.postgres_subnet.id
}

# Outputs
output "postgres_server_name" {
  value = azurerm_postgresql_server.postgres_server.name
}

output "postgres_database_name" {
  value = azurerm_postgresql_database.postgres_db.name
}