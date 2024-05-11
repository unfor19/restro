

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

variable "budget_amount" {
  description = "The budget amount for the Azure subscription - USD $"
  type        = number
  default     = 20
}

variable "vnet_address_space" {
  description = "The address space for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "budget_threshold" {
  description = "The threshold for the budget - Percentage of the budget amount"
  type        = number
  default     = 80
}

variable "budget_notification_emails" {
  description = "The email addresses to notify when the budget is exceeded - Commas separate multiple emails"
  type        = string
  default     = ""
  sensitive   = true
}

variable "docker_image" {
  description = "The Docker image to deploy to the web app"
  type        = string
  default     = "unfor19/restro"
}

variable "docker_tag" {
  description = "The Docker image tag to deploy to the web app"
  type        = string
  default     = "latest"
}

variable "docker_enable_ci" {
  description = "Enable CI/CD for the Docker image"
  type        = bool
  default     = false
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

  budget_notification_emails = try(split(",", var.budget_notification_emails), [])

  hostname = var.hostname
}
