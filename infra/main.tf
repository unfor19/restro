
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
