# Azure Provider
# For now, we'll log into AZURE CLI manually for auth
# Do this by running 'az login' and following the instructions

provider "azurerm" {
  # Use v2.1.0 to avoid authorisation error creating storage area on 2.0.0
  version = "=2.1.0"
  features {}
}

