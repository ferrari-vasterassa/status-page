# Grab a public address
resource "azurerm_public_ip" "ip-1" {
  name                         = "ip-1"
  location                     = var.az_region
  resource_group_name          = azurerm_resource_group.status-page-rg.name
  allocation_method            = "Dynamic"
}

