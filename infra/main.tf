
# Create the resource group
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = "eastus"
}

# Create the Linux App Service Plan
resource "azurerm_service_plan" "appserviceplan" {
  name                = "${var.project_name}-${local.random_number}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1" # F1 and Y1 are not supported
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
    app_command_line    = "python3 main.py"


    application_stack {
      python_version = 3.9
    }
  }
}
