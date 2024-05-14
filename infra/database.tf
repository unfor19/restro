resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = "${var.project_name}-webapp-cosmosdb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"
  free_tier_enabled   = true

  capacity {
    total_throughput_limit = var.db_total_throughput
  }

  backup {
    # https://learn.microsoft.com/en-us/azure/cosmos-db/periodic-backup-storage-redundancy
    retention_in_hours  = 24 * var.db_backup_retention_days
    interval_in_minutes = 60 * var.db_backup_hours_interval
    # https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy#redundancy-in-the-primary-region
    storage_redundancy = var.db_backup_storage_redundancy
    type               = "Periodic"
  }

  # Must enable this, otherwise getting:
  # pymongo.errors.ServerSelectionTimeoutError: Request blocked by network firewall
  public_network_access_enabled = true


  # Defines which subnets are allowed to access the DB
  is_virtual_network_filter_enabled = true
  virtual_network_rule {
    id = azurerm_subnet.private.id
  }

  ip_range_filter = var.db_allowed_public_ips

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }

  consistency_policy {
    consistency_level = "Session"
  }

  capabilities {
    # What is EnableAggregationPipeline
    # https://docs.microsoft.com/en-us/azure/cosmos-db/mongodb-aggregation
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  capabilities {
    name = "MongoDBv3.4"
  }

  capabilities {
    name = "EnableMongo"
  }
}
