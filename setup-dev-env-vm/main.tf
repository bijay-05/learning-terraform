# configure the azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "testrg" {
  name     = "mytestrg"
  location = "centralindia"
  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "test-vnet" {
  name                = "mytestvnet"
  resource_group_name = azurerm_resource_group.testrg.name
  location            = azurerm_resource_group.testrg.location
  address_space       = ["10.123.0.0/16"]

  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "testsubnet" {
  name                 = "mytestsubnet"
  resource_group_name  = azurerm_resource_group.testrg.name
  virtual_network_name = azurerm_virtual_network.test-vnet.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_network_security_group" "testnsg" {
  name                = "mytestnsg"
  resource_group_name = azurerm_resource_group.testrg.name
  location            = azurerm_resource_group.testrg.location

  tags = {
    environment = "dev"
  }


}

resource "azurerm_network_security_rule" "testnsr" {
  name                        = "mytestnsr"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.testrg.name
  network_security_group_name = azurerm_network_security_group.testnsg.name
}

resource "azurerm_subnet_network_security_group_association" "testsnsga" {
  subnet_id                 = azurerm_subnet.testsubnet.id
  network_security_group_id = azurerm_network_security_group.testnsg.id
}

resource "azurerm_public_ip" "testip" {
  name                = "mytestip"
  resource_group_name = azurerm_resource_group.testrg.name
  location            = azurerm_resource_group.testrg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "testnic" {
  name                = "mytestnic"
  location            = azurerm_resource_group.testrg.location
  resource_group_name = azurerm_resource_group.testrg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.testsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.testip.id
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "testvm" {
  name                = "mytestvm"
  resource_group_name = azurerm_resource_group.testrg.name
  location            = azurerm_resource_group.testrg.location
  size                = "Standard_B2s"
  admin_username      = "vm-user-name"

  network_interface_ids = [
    azurerm_network_interface.testnic.id,
  ]

  # custom_data = filebase64("./customdata.tftpl")

  

  admin_ssh_key {
    username   = "vm-user-name"
    public_key = file("/path/to/public/ssh-key")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  connection {
      type = "ssh"
      user = "vm-user-name"
      private_key = file("/path/to/local/private/ssh_keys")
      host = self.public_ip_address
  }

  provisioner "local-exec" {
    command = templatefile("linux-ssh-scripts.tftpl", {
      hostname     = self.public_ip_address,
      user         = "vm-user-name",
      identityfile = "/path/to/local/private/ssh_keys"
    })
    interpreter = ["bash", "-c"]
  }
  provisioner "file" {
    source      = "./nvm-install.sh"
    destination = "setup.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "bash ~/setup.sh",
      # "source ~/.bashrc" cannot perform this on script
    ]
  }
}
