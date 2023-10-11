terraform {
  required_providers {
    azurerm ={
        source = "hashicorp/azurerm"
        version = "=3.0.0"
    }
  }
}
provider "azurerm" {
  features {}

  subscription_id = "8d1a54bc-c2f3-4cf2-b266-bf1c9b117bcc"
  tenant_id = "5b50b9b5-69ac-4622-8486-aff896b60fdb"
  client_id = "d727fb40-ad10-4acc-895b-a3a4254b5f39"
  client_secret = "9b761923-0f1b-4a43-8882-07ccfd35e7bb"
  
}
resource "azurerm_resource_group" "terraform_rg" {
name = "terraform.rg"
location = "south India"
}
resource "azurerm_virtual_network" "terraform_rg_vnet" {
  name                = "terraform.rg.vnet"
  resource_group_name = azurerm_resource_group.terraform_rg.name
  location            = azurerm_resource_group.terraform_rg.location
  address_space       = ["10.0.0.0/16"]
}
resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.terraform_rg.name
  virtual_network_name = azurerm_virtual_network.terraform_rg_vnet.name
  address_prefixes     = ["10.0.0.0/16"]
}
resource "azurerm_network_interface" "main" {
  name                = "tfvm001.nic"
  location            = azurerm_resource_group.terraform_rg.location
  resource_group_name = azurerm_resource_group.terraform_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_network_security_group" "tfvm_nsg" {
  name                = "tfvm.nsg"
  location            = azurerm_resource_group.terraform_rg.location
  resource_group_name = azurerm_resource_group.terraform_rg.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Dev"
  }
}
resource "azurerm_virtual_machine" "tfvm001" {
  name                  = "tfvm001"
  location              = azurerm_resource_group.terraform_rg.location
  resource_group_name   = azurerm_resource_group.terraform_rg.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"


  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "Dev"
  }
}