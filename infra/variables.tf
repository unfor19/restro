

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "location" {
  description = "The Azure region to deploy the resources"
  type        = string
  default     = "northeurope"
}

variable "service_plan_sku_name" {
  description = "The SKU name for the App Service Plan - F1 and Y1 are NOT supported"
  type        = string
  default     = "B1"
}

variable "random_integer" {
  description = "A random integer to append to resource names"
  type        = number
  default     = 23
}

variable "hostname" {
  description = "The hostname for the web app"
  type        = string
  default     = ""
}

locals {
  random_number       = var.random_integer
  resource_group_name = "${var.project_name}-rg-${local.random_number}"

  cloudflare_ips = [
    # https://www.cloudflare.com/ips-v4/#
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "172.64.0.0/13",
    "131.0.72.0/22"
  ]

  hostname = var.hostname
}
