provider "azurerm" {
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  features {}
}

variable "subscription_id"  {
    description=""
}

variable "client_id"  {
    description=""
}

variable "client_secret"  {
    description=""
}

variable "tenant_id"  {
    description=""
}

variable "location" {
  description = ""
}


variable "vnet_cidr" {
  description = "Virtual Network"
  default     = "ReactorNetwork1"
}

variable "subnet1_cidr" {
  description = "Subnet 1"
  default     = "10.0.1.0/24"
}

variable "subnet2_cidr" {
  description = "Subnet 2"
  default     = "10.0.2.0/24"
  #default     = "192.168.0.0/16"
}

variable "subnet3_cidr" {
  description = "Subnet 3"
  default     = "10.0.3.0/24"
  #default     = "192.168.0.0/16"
}

variable "subnet4_cidr" {
  description = "Subnet 4"
  default     = "10.0.5.0/27"
}


variable "vm_username" {
  description = "azure-admin"
  default     = "azure-admin"
}

variable "vm_password" {
  description = "Pentium4"
  default     = "Pentium4"
}
