
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "webapp_name" {
  value = azurerm_linux_web_app.webapp.name
}


locals {
  default_hostname = azurerm_linux_web_app.webapp.default_hostname
}

output "webapp_url" {
  value = local.default_hostname
}

