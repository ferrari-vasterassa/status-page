# Azure Provider
# For now, we'll log into AZURE CLI manually for auth
# Do this by running 'az login' and following the instructions

provider "azurerm" {
  # Stick to v2.0.0, as that is what is in the terraform provider example
  version = "=2.0.0"
  features {}
}

