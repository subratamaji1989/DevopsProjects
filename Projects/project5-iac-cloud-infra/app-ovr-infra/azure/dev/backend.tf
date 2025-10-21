terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstateacmedev" # Example value
    container_name       = "tfstate"
    key                  = "app-ovr-infra/dev/infra-stack.tfstate"
  }
}