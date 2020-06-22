# Grab a public address
resource "azurerm_public_ip" "public_ip_1" {
  name                         = "public_ip_1"
  location                     = var.az_region
  resource_group_name          = azurerm_resource_group.status_page_rg.name
  allocation_method            = "Dynamic"
}

# Add a NIC
resource "azurerm_network_interface" "vm_1_nic" {
    name                        = "vm_1_nic"
    location                    = var.az_region
    resource_group_name         = azurerm_resource_group.status_page_rg.name

    ip_configuration {
        name                          = "vm_1_nic_ip_config"
        subnet_id                     = azurerm_subnet.status_page_sn.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.public_ip_1.id
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "vm_1_nic_sg" {
    network_interface_id      = azurerm_network_interface.vm_1_nic.id
    network_security_group_id = azurerm_network_security_group.front_end_sg.id
}





resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}

output "tls_private_key" { value = "tls_private_key.example_ssh.private_key_pem" }

resource "azurerm_linux_virtual_machine" "myterraformvm" {
    name                  = "myVM"
    location              = var.az_region
    resource_group_name   = azurerm_resource_group.status_page_rg.name
    network_interface_ids = [azurerm_network_interface.vm_1_nic.id]
    size                  = "Standard_B1s"

    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    computer_name  = "myvm"
    admin_username = "azureuser"
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.example_ssh.public_key_openssh
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.status_page_sa.primary_blob_endpoint
    }
}

