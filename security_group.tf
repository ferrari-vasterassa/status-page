# Securtity group for monitor VMs
resource "azurerm_network_security_group" "front-end-sg" {
  name                = "front-end-sg"
  location            = var.az_region
  resource_group_name = azurerm_resource_group.status-page-rg.name
    
  # Just SSH for now
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

