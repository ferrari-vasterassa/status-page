# Resource group network
resource "azurerm_virtual_network" "status-page-nw" {
  name                = "status-page"
  resource_group_name = azurerm_resource_group.status-page-rg.name
  location            = azurerm_resource_group.status-page-rg.location
  # We only need a few addresses.  Let's pick a random address space unlikely to clash with anything else we deploy in future in this RG
  address_space       = ["10.34.85.0/24"]
}

