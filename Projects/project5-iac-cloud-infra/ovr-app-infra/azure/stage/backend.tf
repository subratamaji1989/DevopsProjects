# This file defines the remote backend for storing Terraform state.
# For CI/CD pipelines, this should be configured to point to a secure Azure Storage Account.
# For local development, you can use the '-backend=false' flag with 'terraform init'.

terraform {
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "tfstatea1b2c3"
  #   container_name       = "tfstate"
  #   key                  = "dev.terraform.tfstate"
  # }
}