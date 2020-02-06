provider "azurerm" {
  version = "~> 1.27"
  subscription_id = "${var.SUBID}"
  client_id = "${var.CLIENTID}"
  client_certificate_path ="${var.CERTPATH}"
  client_certificate_password = "${var.CERTPASS}"
  tenant_id = "${var.TENANTID}"
}

resource "azurerm_resource_group" "resg" {
  name = "terraform-group"
  location = "${var.location}"
  tags = "${var.tags}"
}

resource "azurerm_virtual_network" "myterraformnetwork" {
  name = "terraform_vnet"
  address_space = ["10.0.0.0/16"]
  location = "eastus"
  resource_group_name = "terraform-group"
}

resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.resg.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.resg.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.resg.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "myterraformnic" {
    name                        = "myNIC"
    location                    = "eastus"
    resource_group_name         = azurerm_resource_group.resg.name
    network_security_group_id   = azurerm_network_security_group.myterraformnsg.id

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.resg.name
    }

    byte_length = 8
}

resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.resg.name
    location                    = "eastus"
    account_replication_type    = "LRS"
    account_tier                = "Standard"

    tags = {
        environment = "Terraform Demo"
    }
}


resource azurerm_managed_disk "os_disk" {
  name = "rhelterraform_osdisk"
  location = "eastus"
  resource_group_name = azurerm_resource_group.resg.name
  storage_account_type = "Standard_LRS"
  create_option = "Copy"
  source_resource_id = "/subscriptions/f476e58b-5b40-478c-9ac9-461dc8f39866/resourceGroups/Linux_Training_RG/providers/Microsoft.Compute/snapshots/rhelterraform_snapshot"
  disk_size_gb = "64"
}

resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "${random_id.randomId.hex}_terraform"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.resg.name
    network_interface_ids = [azurerm_network_interface.myterraformnic.id]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = azurerm_managed_disk.os_disk.name
        caching           = "ReadWrite"
        create_option     = "Attach"
        managed_disk_type = "Standard_LRS"
        managed_disk_id   = azurerm_managed_disk.os_disk.id
        os_type           = "Linux"
    }

/*    os_profile {
        computer_name  = "${random_id.randomId.hex}_terraform"
        admin_username = "nick"
        admin_password = "xxxxxxx"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }
*/
    tags = {
        environment = "Terraform Demo"
    }
}
