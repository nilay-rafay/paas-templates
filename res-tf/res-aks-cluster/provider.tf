terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.14.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.7.1"
    }
  }
}

provider "azurerm" {
  features {}
}
