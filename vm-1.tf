# Grab a public address
resource "azurerm_public_ip" "public_ip_1" {
  name                         = "public_ip_1"
  location                     = var.az_region
  resource_group_name          = azurerm_resource_group.status_page_rg.name
  allocation_method            = "Static"
  sku                          = "standard"
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

# Connect the VM security group to the NIC
resource "azurerm_network_interface_security_group_association" "vm_1_nic_sg" {
  network_interface_id      = azurerm_network_interface.vm_1_nic.id
  network_security_group_id = azurerm_network_security_group.vm_sg.id
}

# Add the NIC to the LB
resource "azurerm_network_interface_backend_address_pool_association" "vm_1_lb_pool_assoc" {
  network_interface_id    = azurerm_network_interface.vm_1_nic.id
  ip_configuration_name   = "vm_1_nic_ip_config"
  backend_address_pool_id = azurerm_lb_backend_address_pool.status_page_backend_pool.id
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
    name              = "vm1_OsDisk"
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
    private_key = file("~/.ssh/id_rsa")
    timeout = "2m"
  }

  # Initial config
  provisioner "file" {
    # Monitoring script
    source      = "resources/monitor.py"
    destination = "/tmp/monitor.py"
  }

  provisioner "file" {
    content     = cloudflare_origin_ca_certificate.origin.certificate
    destination = "/tmp/origin.crt"
  }

  provisioner "file" {
    content     = tls_private_key.origin.private_key_pem
    destination = "/tmp/origin.key"
  }

  provisioner "file" {
    source      = "resources/cloudflare-origin-pull.crt"
    destination = "/tmp/cloudflare-origin-pull.crt"
  }

  provisioner "file" {
    # Nginx config
    source      = "resources/nginx.default"
    destination = "/tmp/nginx.default"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      # No need to upgrade, Azure appears to deploy fully-updated
      #"sudo apt -y full-upgrade",
      "sudo apt -y install nginx python3-psycopg2",
      "sudo apt clean",
      # Very hacky, not for use in prod; checks on state of DB values, responds to http on port 8080
      "/usr/bin/screen -d -m python3 /tmp/monitor.py",
      # Insert cloudflare certificates, keys and config into nginx
      "sudo mv /tmp/nginx.default /etc/nginx/sites-available/default",
      "sudo mv /tmp/origin.crt /etc/ssl/certs/",
      "sudo mv /tmp/origin.key /etc/ssl/private/",
      "sudo mv /tmp/cloudflare-origin-pull.crt /etc/ssl/certs/",
      "sudo service nginx restart"
    ]
  }
}

# Backup policy VM association
resource "azurerm_backup_protected_vm" "vm_1_backup_association" {
  resource_group_name = azurerm_resource_group.status_page_rg.name
  recovery_vault_name = azurerm_recovery_services_vault.status_page_backup_vault.name
  source_vm_id        = azurerm_linux_virtual_machine.vm_1.id
  backup_policy_id    = azurerm_backup_policy_vm.status_page_backup_policy.id
}

