data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                = "kv-${var.prefix}-${var.postfix}${var.env}"
  location            = var.location
  resource_group_name = var.rg_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  tags = var.tags
}

# Private Endpoint configuration

resource "azurerm_private_endpoint" "kv_pe" {
  name                = "pe-${azurerm_key_vault.adl_kv.name}-vault"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "psc-kv-${var.basename}"
    private_connection_resource_id = azurerm_key_vault.adl_kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-kv"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  count = var.enable_aml_secure_workspace ? 1 : 0

  tags = var.tags
}