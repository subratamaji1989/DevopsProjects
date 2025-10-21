variable "resource_group_name" {
  description = "The name of the Azure Resource Group."
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
}

variable "container_registries" {
  description = "A map of Azure Container Registry configurations."
  type = map(object({
    name = string
    sku  = string
  }))
}