
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

  app_settings = {
    "DB_CONNECTION_STRING"                  = azurerm_cosmosdb_account.cosmosdb.connection_strings[0],
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.webapp.connection_string,
    WEBSITES_ENABLE_APP_SERVICE_STORAGE     = "false"
    DOCKER_REGISTRY_SERVER_URL              = "https://index.docker.io/v1"
    WEBSITES_PORT                           = "8000"
    DOCKER_ENABLE_CI                        = var.docker_enable_ci
  }

  site_config {
    ftps_state          = "Disabled"
    http2_enabled       = true
    minimum_tls_version = "1.2"
    health_check_path   = "/health"
    application_stack {
      docker_image     = var.docker_image
      docker_image_tag = var.docker_tag
    }

    dynamic "ip_restriction" {
      for_each = local.cloudflare_ips

      content {
        ip_address = ip_restriction.value
        action     = "Allow"
      }
    }

    ip_restriction {
      ip_address = var.vnet_address_space
      action     = "Allow"
    }
  }

  logs {
    application_logs {
      file_system_level = "Information"
    }

    http_logs {
      file_system {
        retention_in_days = 0
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
  address_space       = [var.vnet_address_space]
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


resource "azurerm_consumption_budget_resource_group" "webapp" {
  count             = length(local.budget_notification_emails) > 0 ? 1 : 0
  name              = var.project_name
  resource_group_id = azurerm_resource_group.rg.id
  amount            = var.budget_amount

  time_grain = "Monthly"

  time_period {
    start_date = format("%s-01T00:00:00Z", formatdate("YYYY-MM", timestamp()))
    end_date   = "2052-12-31T23:59:59Z"
  }

  lifecycle {
    ignore_changes = [time_period]
  }

  notification {
    contact_emails = local.budget_notification_emails
    threshold      = var.budget_threshold
    operator       = "GreaterThan"
  }
}


resource "azurerm_log_analytics_workspace" "webapp" {
  name                = "${var.project_name}-${local.random_number}-loganalytics"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}


resource "azurerm_application_insights" "webapp" {
  name                = "${var.project_name}-${local.random_number}-appinsights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.webapp.id
  retention_in_days   = 30
}
