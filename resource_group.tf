# From env.sh:
variable "az_region" {}

# Create a resource group for everything to sit in
resource "azurerm_resource_group" "status-page-rg" {
  name     = "status-page"
  location = var.az_region
}

