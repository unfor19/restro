
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "webapp_name" {
  value = azurerm_linux_web_app.webapp.name
}


locals {
  virtual_ip       = try(azurerm_app_service_custom_hostname_binding.webapp[0].virtual_ip, "")
  default_hostname = azurerm_linux_web_app.webapp.default_hostname
}

output "webapp_url" {
  value = local.default_hostname
}

output "virtual_ip" {
  value = local.virtual_ip
}
