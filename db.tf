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
        # Use a static address so the other VMs know where to connect.
        private_ip_address_allocation = "Static"
        private_ip_address            = "10.34.85.10"
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
  provisioner "file" {
    # Using cron, we'll insert a random value from 0-99 into the DB every minute so we have some data to look at
    source      = "resources/postgres.cron"
    destination = "/tmp/postgres.cron"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      # No need to upgrade, Azure appears to deploy fully-updated
      #"sudo apt -y full-upgrade",
      "sudo apt -y install postgresql postgresql-contrib",
      "sudo apt clean",
      # TODO - set up actual authentication, this is nowhere near secure!
      "echo hostssl all all 10.34.85.0/28 trust | sudo tee -a /etc/postgresql/11/main/pg_hba.conf > /dev/null",
      "echo \"listen_addresses = '*'\" | sudo tee -a /etc/postgresql/11/main/postgresql.conf > /dev/null",
      # Need to do full reload as we're changing listening addresses:
      "sudo service postgresql restart",
      "sudo -u postgres createdb monitoring > /dev/null",
      "echo \"create table monitoring (ts timestamp with time zone not null default now(), value integer not null);\" | sudo -u postgres psql monitoring postgres > /dev/null",
      "sudo -u postgres crontab /tmp/postgres.cron"
    ]
  }
}
/* Hold off on backups for now, makes iteration too slow
# Backup policy VM association
resource "azurerm_backup_protected_vm" "db_vm_backup_association" {
  resource_group_name = azurerm_resource_group.status_page_rg.name
  recovery_vault_name = azurerm_recovery_services_vault.status_page_backup_vault.name
  source_vm_id        = azurerm_linux_virtual_machine.db_vm.id
  backup_policy_id    = azurerm_backup_policy_vm.status_page_backup_policy.id
}
*/
