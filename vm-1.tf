# Grab a public address
resource "azurerm_public_ip" "public-ip-1" {
  name                         = "public-ip-1"
  location                     = var.az_region
  resource_group_name          = azurerm_resource_group.status-page-rg.name
  allocation_method            = "Dynamic"
}

# Add a NIC
resource "azurerm_network_interface" "vm-1-nic" {
    name                        = "vm-1-nic"
    location                    = var.az_region
    resource_group_name         = azurerm_resource_group.status-page-rg.name

    ip_configuration {
        name                          = "vm-1-nic-ip-config"
        subnet_id                     = azurerm_subnet.status-page-sn.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.public-ip-1.id
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "vm-1-nic-sg" {
    network_interface_id      = azurerm_network_interface.vm-1-nic.id
    network_security_group_id = azurerm_network_security_group.front-end-sg.id
}

