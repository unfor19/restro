

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

data "http" "cloudflare_ips" {
  url = "https://www.cloudflare.com/ips-v4/#"
}

variable "db_allowed_public_ips" {
  description = "The allowed public IPs to access the CosmosDB - Comma separated - Use it to connect with MongoDB Compass from your local machine"
  default     = ""
}

variable "db_backup_retention_days" {
  description = "The retention days for the CosmosDB"
  type        = number
  default     = 5
}

variable "db_backup_hours_interval" {
  description = "The interval in hours for the CosmosDB backup"
  type        = number
  default     = 3
}

variable "db_backup_storage_redundancy" {
  description = "The storage redundancy for the CosmosDB backup - Geo, Local, Zone"
  type        = string
  default     = "Local"
  validation {
    condition     = var.db_backup_storage_redundancy == "Geo" || var.db_backup_storage_redundancy == "Local" || var.db_backup_storage_redundancy == "Zone"
    error_message = "The storage redundancy must be Geo, Local, or Zone"
  }
}

variable "db_total_throughput" {
  description = "The total throughput for the CosmosDB"
  type        = number
  default     = 400
  validation {
    condition     = var.db_total_throughput >= 100 && var.db_total_throughput <= 1000
    error_message = "The total throughput must be between 400 and 1000 to keep it free"
  }
}

locals {
  random_number       = var.random_integer
  resource_group_name = "${var.project_name}-rg-${local.random_number}"

  cloudflare_ips = try(split("\n", data.http.cloudflare_ips.response_body), [])

  budget_notification_emails = try(split(",", var.budget_notification_emails), [])

  hostname = var.hostname
}
