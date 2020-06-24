# Grab a public IP for the LB
resource "azurerm_public_ip" "lb_ip" {
  name                = "lb_ip"
  location            = var.az_region
  resource_group_name = azurerm_resource_group.status_page_rg.name
  allocation_method   = "Static"
  sku                 = "standard"
}

# Set up the LB
resource "azurerm_lb" "status_page_lb" {
  name                = "status_page_lb"
  location            = var.az_region
  resource_group_name = azurerm_resource_group.status_page_rg.name
  sku                 = "standard"

  frontend_ip_configuration {
    name                 = "lb_ip"
    public_ip_address_id = azurerm_public_ip.lb_ip.id
  }
}

# Set up the healthcheck
resource "azurerm_lb_probe" "status_page_healthcheck" {
  resource_group_name = azurerm_resource_group.status_page_rg.name
  loadbalancer_id     = azurerm_lb.status_page_lb.id
  name                = "tcp_80_probe"
  port                = 80
}

# Add TCP/443 service
resource "azurerm_lb_rule" "status_page_tcp_80_service" {
  resource_group_name            = azurerm_resource_group.status_page_rg.name
  loadbalancer_id                = azurerm_lb.status_page_lb.id
  name                           = "status_page_lb_80_rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "lb_ip"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.status_page_backend_pool.id
  probe_id                       = azurerm_lb_probe.status_page_healthcheck.id
}

# Add backend IP pool
resource "azurerm_lb_backend_address_pool" "status_page_backend_pool" {
  resource_group_name = azurerm_resource_group.status_page_rg.name
  loadbalancer_id     = azurerm_lb.status_page_lb.id
  name                = "status_page_backend_pool"
}

// TODO - there must be a way to apply a security group to an LB front-end IP

