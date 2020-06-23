# Azure provider
# For now, we'll log into AZURE CLI manually for auth
# Do this by running 'az login' and following the instructions

provider "azurerm" {
  # Use the latest version:
  version = "=2.15.0"
  features {}
}

