/* Hold off on backups for now, makes iteration too slow
# Create a backup vault
resource "azurerm_recovery_services_vault" "status_page_backup_vault" {
  # Name can't include underscores
  name                = "status-page-backup-vault"
  location            = azurerm_resource_group.status_page_rg.location
  resource_group_name = azurerm_resource_group.status_page_rg.name
  sku                 = "Standard"
}

# Create a backup policy
resource "azurerm_backup_policy_vm" "status_page_backup_policy" {
  name                = "status_page_backup_policy"
  resource_group_name = azurerm_resource_group.status_page_rg.name
  recovery_vault_name = azurerm_recovery_services_vault.status_page_backup_vault.name

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 10
  }
}
*/
