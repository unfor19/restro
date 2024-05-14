# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.103.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
  required_version = ">= 1.6.0"

  backend "azurerm" {
    # Must hardcode these values
    resource_group_name  = "restro-rg-tfstate"
    storage_account_name = "restrostoragetfstate"
    container_name       = "restrocontainertfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
