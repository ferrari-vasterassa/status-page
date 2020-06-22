# Random ID to name the storage account
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.status_page_rg.name
  }
  byte_length = 8
}


# Create a storage account
resource "azurerm_storage_account" "status_page_sa" {
  name                        = "diag${random_id.randomId.hex}"
  resource_group_name         = azurerm_resource_group.status_page_rg.name
  location                    = var.az_region
  # Locally-redundant storage
  account_replication_type    = "LRS"
  account_tier                = "Standard"
}

