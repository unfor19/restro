resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = "${var.project_name}-webapp-cosmosdb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"
  enable_free_tier    = true

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


resource "azurerm_cosmosdb_mongo_database" "database" {
  name                = var.project_name
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmosdb.name
  throughput          = 1000
}

resource "azurerm_cosmosdb_mongo_collection" "collection" {
  name                = "restaurants"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmosdb.name
  database_name       = azurerm_cosmosdb_mongo_database.database.name

  shard_key  = "uniqueKey"
  throughput = 400

  index {
    keys   = ["_id"]
    unique = true
  }
}
