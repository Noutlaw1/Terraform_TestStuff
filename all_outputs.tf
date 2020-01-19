data "azurerm_subscription" "current" {}

output "target_azure_subscription" {
  value = "${data.azurerm_subscription.current.display_name}"
}
