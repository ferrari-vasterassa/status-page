# Resource group network
resource "azurerm_virtual_network" "virtual-nw" {
  name                = "status-page-nw"
  resource_group_name = azurerm_resource_group.status-page-rg.name
  location            = azurerm_resource_group.status-page-rg.location
  # Let's pick a random address space unlikely to clash with anything else we deploy in future in this RG or elsewhere.
  address_space       = ["10.34.85.0/24"]
}

# Status page network
resource "azurerm_subnet" "status-page-sn" {
  name                 = "status-page-sn"
  resource_group_name  = azurerm_resource_group.status-page-rg.name
  virtual_network_name = azurerm_virtual_network.virtual-nw.name
  # Acutal subnet we'll use.  Doesn't need to be big.
  address_prefix       = "10.34.85.0/28"
}

