# Azure provider
# For now, we'll log into AZURE CLI manually for auth
# Do this by running 'az login' and following the instructions

provider "azurerm" {
  # Use v2.1.0 to avoid authorisation error creating storage area on 2.0.0
  version = "=2.1.0"
  features {}
}

# Cloudflare provider values (from environment variables)
variable "cloudflare_email" {}
variable "cloudflare_api_key" {}
variable "cloudflare_api_user_service_key" {}
variable "cloudflare_zone_filter" {}

provider "cloudflare" {
  email = var.cloudflare_email
  api_key = var.cloudflare_api_key
  api_user_service_key = var.cloudflare_api_user_service_key
}

