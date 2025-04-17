data "azurerm_subscription" "current" {}

resource "azurerm_user_assigned_identity" "workload_identity" {
  for_each            = var.workload_identity_enabled ? var.workload_identities : {}
  name                = each.value.name
  resource_group_name = each.value.resource_group != "" ? each.value.resource_group : var.resource_group
  location            = each.value.location != "" ? each.value.location : var.location
  tags                = each.value.tags
}

resource "azurerm_federated_identity_credential" "workload_identity" {
  for_each            = var.workload_identity_enabled ? var.workload_identities : {}
  name                = each.value.name
  resource_group_name = azurerm_user_assigned_identity.workload_identity[each.key].resource_group_name
  parent_id           = azurerm_user_assigned_identity.workload_identity[each.key].id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject             = "system:serviceaccount:${each.value.sa_namespaces[0].sa_namespace}:${each.value.sa_namespaces[0].sa_name}"
}

data "azurerm_role_definition" "roles" {
  for_each = var.workload_identity_enabled ? toset(flatten([for identity in var.workload_identities : [for ra in identity.roleAssignments : ra.role]])) : []
  name     = each.key
}

resource "azurerm_key_vault" "workload_identity_key_vault" {
  count               = var.workload_identity_enabled ? 1 : 0
  name                = var.workload_identity_key_vault_name
  location            = var.location
  resource_group_name = var.resource_group
  sku_name            = "standard"
  tenant_id           = data.azurerm_subscription.current.tenant_id
}

resource "azurerm_role_assignment" "workload_identity_role_assignment" {
  for_each           = var.workload_identity_enabled ? { for k, v in var.workload_identities : k => [for ra in v.roleAssignments : { role = ra.role, scope = ra.scope, principal_id = azurerm_user_assigned_identity.workload_identity[k].principal_id }] } : {}
  role_definition_id = data.azurerm_role_definition.roles[each.value[0].role].id
  principal_id       = each.value[0].principal_id
  scope              = each.value[0].scope
}
