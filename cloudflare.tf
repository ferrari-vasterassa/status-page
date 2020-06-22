data "cloudflare_zones" "status_page_cf_zones" {
  filter {
    name   = var.cloudflare_zone_filter
    status = "active"
    paused = false
  }
}

resource "cloudflare_record" "status_page" {
  zone_id = lookup(data.cloudflare_zones.status_page_cf_zones.zones[0], "id")
  # DNS record name to create (A/AAAA)
  name    = "status-page"
  # Initially just setting this to vm-1 public IP
  value   = azurerm_linux_virtual_machine.vm_1.public_ip_address
  type    = "A"
  proxied = true
}

resource "tls_private_key" "origin" {
  # nginx doesn't seem to like ECDSA origin pull certs TODO find a way to fix this, ECDSA is better!
  algorithm = "RSA"
}

resource "tls_cert_request" "origin" {
  key_algorithm   = tls_private_key.origin.algorithm
  private_key_pem = tls_private_key.origin.private_key_pem

  subject {
    common_name  = var.cloudflare_hostname
    organization = "Widgets, Inc"
  }
}

resource "cloudflare_origin_ca_certificate" "origin" {
  csr                = tls_cert_request.origin.cert_request_pem
  hostnames          = [ var.cloudflare_zone_filter ]
  request_type       = "origin-rsa"
  requested_validity = 7
  
}

