
# creation de ma ressource 
resource "azurerm_resource_group" "resource_gp" {
    name = "IVI-Lab-2020"
    location = var.location
}


# creation de ma Vnet 
resource "azurerm_virtual_network" "ivi_vnet" {
  name                = "IVI-LAB-VNet"
  address_space       =  ["10.0.0.0/16"] 
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_gp.name


}

# creation de mon sous reseau numero 1
resource "azurerm_subnet" "IVI_subnet_1" {
  name                 = "IVI-Subnet-1"
  address_prefixes       = [var.subnet1_cidr]
  virtual_network_name = azurerm_virtual_network.ivi_vnet.name
  resource_group_name  = azurerm_resource_group.resource_gp.name
}

# creation de mon sous reseau numer 2
resource "azurerm_subnet" "IVI_subnet_2" {
  name                 = "IVI-Subnet-2"
  address_prefixes       = [var.subnet2_cidr]
  virtual_network_name = azurerm_virtual_network.ivi_vnet.name
  resource_group_name  = azurerm_resource_group.resource_gp.name
}

# creation de mon sous reseau numer 3
resource "azurerm_subnet" "IVI_subnet_3" {
  name                 = "IVI-Subnet-3"
  address_prefixes       = [var.subnet3_cidr]
  virtual_network_name = azurerm_virtual_network.ivi_vnet.name
  resource_group_name  = azurerm_resource_group.resource_gp.name
  service_endpoints    = ["Microsoft.Sql"]
}


# creation de mon sous reseau numer 4 azure bastion
resource "azurerm_subnet" "IVI_subnet_4_bastion" {
  name                 = "AzureBastionSubnet"
  address_prefixes       = [var.subnet4_cidr]
  virtual_network_name = azurerm_virtual_network.ivi_vnet.name
  resource_group_name  = azurerm_resource_group.resource_gp.name
}

# creation de mon adresse IP public 

resource "azurerm_public_ip" "IVI_pip" {
  name                         = "IVI-PIP"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.resource_gp.name
  #public_ip_address_allocation = "static"
  allocation_method = "Static"


}

resource "azurerm_public_ip" "IVI_pip_bastion" {
  name                         = "IVI-PIP-bastion"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.resource_gp.name
  #public_ip_address_allocation = "static"
  allocation_method = "Static"


}

# creation de mon interface reseau 
resource "azurerm_network_interface" "public_nic" {
  name                      = "IVI-ACCES-PUBLIC"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.resource_gp.name
  #network_security_group_id = azurerm_network_security_group.nsg_public.id

  ip_configuration {
    name                          = "IVI-ACCES-Public"
    subnet_id                     = azurerm_subnet.IVI_subnet_1.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.IVI_pip.id
  }

 
}

#creation vpn 
resource "azurerm_network_interface" "private_nic_middle" {
  name                      = "IVI-middle"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.resource_gp.name
  #network_security_group_id = azurerm_network_security_group.nsg_middle.id

  ip_configuration {
    name                          = "IVI-middle_Private"
    subnet_id                     = azurerm_subnet.IVI_subnet_2.id
    private_ip_address_allocation = "static"
    private_ip_address            = "10.0.2.5"
  }
}
resource "azurerm_network_security_group" "ivi_nsg_middle" {
  name                = "ivi-middle-nsg"
  location            = azurerm_resource_group.resource_gp.location
  resource_group_name = azurerm_resource_group.resource_gp.name

  security_rule {
    name                       = "ivi-inbound-web-security_rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "137.117.39.115" #"10.0.1.4"
    destination_address_prefix = "*"
  }

# Gestion interdiction accès à tout à partir de ce sous-reseau
  security_rule {
    name                       = "ivi-outbound-web-security_rule"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "ivi-outbound-web-middle-security_rule"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.3.0"
  }
  

}


resource "azurerm_subnet_network_security_group_association" "ivi_nsg_association" {
  subnet_id                 = azurerm_subnet.IVI_subnet_2.id
  network_security_group_id = azurerm_network_security_group.ivi_nsg_middle.id
}





resource "azurerm_network_interface" "private_nic_db" {
  name                      = "IVI-DB"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.resource_gp.name
  #network_security_group_id = azurerm_network_security_group.nsg_db.id

  ip_configuration {
    name                          = "IVI-DBPrivate"
    subnet_id                     = azurerm_subnet.IVI_subnet_3.id
    private_ip_address_allocation = "static"
    private_ip_address            = "10.0.3.5"
  }


}


# Creation de ma VM acces public 

resource "azurerm_virtual_machine" "IVI_frontend" {
  name                  = "IVI-Windows"
  location              = var.location
  resource_group_name   = azurerm_resource_group.resource_gp.name
  network_interface_ids = [azurerm_network_interface.public_nic.id]
  vm_size               = "Standard_DS1_v2"

  #This will delete the OS disk and data disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  storage_image_reference {
    
     offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "azurerm_resource_group.resource_gp.name-OSdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "ubuntuweb"
    admin_username = var.vm_username
    admin_password = var.vm_password

    #admin_password = "data.external.azure_secrets.result.admin-password"
  }

#  os_profile_windows_config {
#    disable_password_authentication = false
#  }

 os_profile_windows_config { 
    provision_vm_agent = true
  }

}





# Creation de ma VM acces private 

resource "azurerm_virtual_machine" "IVI_middle" {
  name                  = "IVI-Linux-middle"
  location              = var.location
  resource_group_name   = azurerm_resource_group.resource_gp.name
  network_interface_ids = [azurerm_network_interface.private_nic_middle.id]
  vm_size               = "Standard_DS1_v2"

  #This will delete the OS disk and data disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "azurerm_resource_group.name-OSdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "ubuntumiddle"
    admin_username = var.vm_username
    admin_password = var.vm_password

    #admin_password = "data.external.azure_secrets.result.admin-password"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

#provisioner "local-exec" {
#    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook ./provision/environment/dev/playbooks/webservers.yml -i ./provision/environment/dev/inventory/inventory"
#  }

}



##############################

resource "azurerm_storage_account" "ividatabaseacount" {
  name                     = "mydatabaseaccount"
  resource_group_name      = azurerm_resource_group.resource_gp.name
  location                 = azurerm_resource_group.resource_gp.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}


resource "azurerm_sql_server" "ivisqlserver" {
  name                         = "myiviazuresqlserver"
  resource_group_name          = azurerm_resource_group.resource_gp.name
  location                     = azurerm_resource_group.resource_gp.location
  version                      = "12.0"
  administrator_login          = var.vm_username
  administrator_login_password = var.vm_password

}

resource "azurerm_sql_firewall_rule" "ivi_firewall_db" {
  name                = "ivi_firewall_db_rule"
  resource_group_name = azurerm_resource_group.resource_gp.name
  server_name         = azurerm_sql_server.ivisqlserver.name
  start_ip_address    = "10.0.2.0"
  end_ip_address      = "10.0.2.0"
}


# creation de la base de données 
resource "azurerm_mssql_database" "mydatabase" {
  name           = "dbmydatabase"
  server_id      = azurerm_sql_server.ivisqlserver.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  #read_scale     = true
  #sku_name       = "BC_Gen5_2"
  #zone_redundant = true

  extended_auditing_policy {
    storage_endpoint                        = azurerm_storage_account.ividatabaseacount.primary_blob_endpoint
    storage_account_access_key              = azurerm_storage_account.ividatabaseacount.primary_access_key
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 6
  }

 

}

##############################

#resource "azurerm_virtual_machine" "IVI-sql" {
  #name                  = "ivi-SQL-VM"
  ##location              = azurerm_resource_group.resource_gp.location
  #resource_group_name   = azurerm_resource_group.resource_gp.name
  #network_interface_ids = [azurerm_network_interface.private_nic_db.id]
  #vm_size               = "Standard_DS14_v2"

 # storage_image_reference {
 #   publisher = "MicrosoftSQLServer"
 #   offer     = "SQL2017-WS2016"
 #   sku       = "SQLDEV"
 #   version   = "latest"
 # }

 # storage_os_disk {
 #   name              = "IVI-OSDisk"
 #   caching           = "ReadOnly"
 #   create_option     = "FromImage"
 #   managed_disk_type = "Premium_LRS"
 # }

 # os_profile {
 #   computer_name  = "winhost01"
 #   admin_username = "exampleadmin"
 #   admin_password = "Password1234!"
 # }

#  os_profile_windows_config {
#    timezone                  = "Pacific Standard Time"
#    provision_vm_agent        = true
#    enable_automatic_upgrades = true
#  }
#}





#resource "azurerm_subnet" "IVI_subnet_4" {
#  name                 = "AzureBastionSubnet"
#  resource_group_name  = azurerm_resource_group.resource_gp.name
#  virtual_network_name = azurerm_virtual_network.ivi_vnet.name
#  address_prefixes       = "10.0.3.0/27"
#}

# creation de mon sous reseau numer 4
resource "azurerm_subnet" "IVI_subnet_4" {
  name                 = "AzureBastionSubnet"
  address_prefixes       = [var.subnet4_cidr]
  virtual_network_name = azurerm_virtual_network.ivi_vnet.name
  resource_group_name  = azurerm_resource_group.resource_gp.name
}


#resource "azurerm_bastion_host" "IVI-azureBastion" {
#  name                = "Acces_VM_bastion"
#  location            = azurerm_resource_group.resource_gp.location
#  resource_group_name = azurerm_resource_group.resource_gp.name

#  ip_configuration {
#    name                 = "configuration"
#    subnet_id            = azurerm_subnet.IVI_subnet_4.id
#    public_ip_address_id = azurerm_public_ip.IVI_pip_bastion.id
#  }
#}

  
  

