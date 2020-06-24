# From env.sh:
variable "az_region" {}

# Create a resource group for everything to sit in
resource "azurerm_resource_group" "status_page_rg" {
  name     = "status_page_rg_3"
  location = var.az_region
}

