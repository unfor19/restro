
# Create the resource group
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
}

# Create the Linux App Service Plan
resource "azurerm_service_plan" "appserviceplan" {
  name                = "${var.project_name}-${local.random_number}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = var.service_plan_sku_name
}

# Create the web app, pass in the App Service Plan ID
resource "azurerm_linux_web_app" "webapp" {
  name                = "${var.project_name}-${local.random_number}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.appserviceplan.id
  https_only          = true

  site_config {
    minimum_tls_version = "1.2"
    health_check_path   = "/health"
    app_command_line    = "python3 -m gunicorn -w 4 'app:app'"


    application_stack {
      python_version = 3.9
    }

    dynamic "ip_restriction" {
      for_each = local.cloudflare_ips

      content {
        ip_address = ip_restriction.value
        action     = "Allow"
      }
    }
  }

  logs {
    application_logs {
      file_system_level = "Information"
    }

    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }
}


resource "azurerm_app_service_custom_hostname_binding" "webapp" {
  count               = local.hostname != "" ? 1 : 0
  hostname            = local.hostname
  resource_group_name = azurerm_resource_group.rg.name
  app_service_name    = azurerm_linux_web_app.webapp.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project_name}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "private" {
  name                 = "${var.project_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
  service_endpoints    = ["Microsoft.AzureCosmosDB"]

  delegation {
    name = "webapp-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "webapp" {
  app_service_id = azurerm_linux_web_app.webapp.id
  subnet_id      = azurerm_subnet.private.id
}



resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                          = "${var.project_name}-webapp-cosmosdb"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  offer_type                    = "Standard"
  kind                          = "MongoDB"
  enable_free_tier              = true
  public_network_access_enabled = false


  # Defines which subnets are allowed to access the DB
  is_virtual_network_filter_enabled = true
  virtual_network_rule {
    id = azurerm_subnet.private.id
  }

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

  default_ttl_seconds = "1000"
  shard_key           = "uniqueKey"
  throughput          = 400

  index {
    keys   = ["_id"]
    unique = true
  }
}

resource "azurerm_consumption_budget_resource_group" "webapp" {
  name              = var.project_name
  resource_group_id = azurerm_resource_group.rg.id
  amount            = 20.0

  time_grain = "Monthly"

  time_period {
    start_date = format("%s-01T00:00:00Z", formatdate("YYYY-MM", timestamp()))
    end_date   = "2052-12-31T23:59:59Z"
  }
  notification {
    contact_roles = ["Owner", "Contributor"]
    threshold     = 80
    operator      = "GreaterThan"
  }
}
