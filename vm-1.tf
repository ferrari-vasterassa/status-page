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

# Create the VM!
resource "azurerm_linux_virtual_machine" "vm_1" {
  name                  = "vm_1"
  location              = var.az_region
  resource_group_name   = azurerm_resource_group.status_page_rg.name
  network_interface_ids = [azurerm_network_interface.vm_1_nic.id]
  # Pretty small please, I'm not made of money!
  size                  = "Standard_B1s"

  os_disk {
    name              = "myOsDisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-10"
    sku       = "10"
    version   = "latest"
  }

  computer_name  = "vm1"
  admin_username = "azureuser"
  disable_password_authentication = true
        
  admin_ssh_key {
    username       = "azureuser"
    # No ECDSA support on Azure yet, apparently!
    public_key     = file("~/.ssh/id_rsa.pub")
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.status_page_sa.primary_blob_endpoint
  }

  # Connection so we can do initial config:
  connection {
    host = self.public_ip_address
    user = "azureuser"
    type = "ssh"
    private_key = file("~/.ssh/id_rsa.pub")
    timeout = "2m"
  }

  # Initial config
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      # No need to upgrade, Azure appears to deploy fully-updated
      #"sudo apt -y full-upgrade",
      "sudo apt -y install nginx",
      "sudo apt clean",
    ]
  }
}

