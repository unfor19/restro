# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
  }
  required_version = ">= 1.6.0"

  backend "azurerm" {
    # Must hardcode these values
    resource_group_name  = "restro-rg"
    storage_account_name = "restrostorage"
    container_name       = "restrocontainer"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
