# Grab a public address
resource "azurerm_public_ip" "public_ip_4" {
  name                         = "public_ip_4"
  location                     = var.az_region
  resource_group_name          = azurerm_resource_group.status_page_rg.name
  allocation_method            = "Static"
  sku                          = "standard"
}

# Add a NIC
resource "azurerm_network_interface" "db_vm_nic" {
    name                        = "db_vm_nic"
    location                    = var.az_region
    resource_group_name         = azurerm_resource_group.status_page_rg.name

    ip_configuration {
        name                          = "db_vm_nic_ip_config"
        subnet_id                     = azurerm_subnet.status_page_sn.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.public_ip_4.id
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "db_vm_nic_sg" {
  network_interface_id      = azurerm_network_interface.db_vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_sg.id
}

# Create the VM!
resource "azurerm_linux_virtual_machine" "db_vm" {
  name                  = "db_vm"
  location              = var.az_region
  resource_group_name   = azurerm_resource_group.status_page_rg.name
  network_interface_ids = [azurerm_network_interface.db_vm_nic.id]
  # Pretty small please, I'm not made of money!
  size                  = "Standard_B1s"

  os_disk {
    name              = "db_vm_OsDisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-10"
    sku       = "10"
    version   = "latest"
  }

  computer_name  = "dbvm"
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
    private_key = file("~/.ssh/id_rsa")
    timeout = "2m"
  }

  # Initial config
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      # No need to upgrade, Azure appears to deploy fully-updated
      #"sudo apt -y full-upgrade",
      "sudo apt -y install postgresql postgresql-contrib",
      "sudo apt clean"
    ]
  }
}

# Backup policy VM association
resource "azurerm_backup_protected_vm" "db_vm_backup_association" {
  resource_group_name = azurerm_resource_group.status_page_rg.name
  recovery_vault_name = azurerm_recovery_services_vault.status_page_backup_vault.name
  source_vm_id        = azurerm_linux_virtual_machine.db_vm.id
  backup_policy_id    = azurerm_backup_policy_vm.status_page_backup_policy.id
}

