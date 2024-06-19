terraform {
   required_version = ">= 1.4.6"
   required_providers {
      azurerm = {
         source  = "hashicorp/azurerm"
         version = "=3.0.0"
      }
   }
   cloud {
      organization = "ky3ow-org"

      workspaces {
         name = "blog"
      }
   }
}

provider "azurerm" {
    features {}
}

resource "azurerm_resource_group" "blog" {
    name = "blog-resources"
    location = "West Europe"
}

resource "azurerm_virtual_network" "blogvnet" {
    name = "blog-vnet"
    resource_group_name = azurerm_resource_group.blog.name
    location = azurerm_resource_group.blog.location
    address_space = [ "10.0.0.0/16" ]
}

resource "azurerm_subnet" "blogsubnet" {
    name = "blog-subnet"
    resource_group_name = azurerm_resource_group.blog.name
    virtual_network_name = azurerm_virtual_network.blogvnet.name
    address_prefixes = [ "10.0.1.0/24" ]
}

resource "azurerm_public_ip" "blogip" {
   name = "blog-public-ip"
   resource_group_name = azurerm_resource_group.blog.name
   location = azurerm_resource_group.blog.location
   allocation_method = "Dynamic"
}

resource "azurerm_network_interface" "blognic" {
   name = "blog-nic"
   resource_group_name = azurerm_resource_group.blog.name
   location = azurerm_resource_group.blog.location
   
   ip_configuration {
      name = "internal"
      subnet_id = azurerm_subnet.blogsubnet.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id = azurerm_public_ip.blogip.id
   }
}

resource "azurerm_linux_virtual_machine" "blogvm" {
   name = "blog-vm"
   resource_group_name = azurerm_resource_group.blog.name
   location = azurerm_resource_group.blog.location
   size = "Standard_B1s"
   admin_username = "blog"
   network_interface_ids = [
      azurerm_network_interface.blognic.id,
   ]

   admin_ssh_key {
      username = "blog"
      public_key = file("${path.module}/id_rsa.pub")
   }

   os_disk {
      caching = "ReadWrite"
      storage_account_type = "Standard_LRS"
   }

   source_image_reference {
      publisher = "RedHat"
      offer = "RHEL"
      sku = "8-lvm-gen2"
      version = "latest"
   }

   custom_data = base64encode(file("${path.module}/cloud-init.cfg"))
}

resource "azurerm_dns_zone" "ky3owxyz" {
   name = "ky3ow.xyz"
   resource_group_name = azurerm_resource_group.blog.name
}

resource "azurerm_dns_a_record" "mainrecord" {
   name = "@"
   resource_group_name = azurerm_resource_group.blog.name
   zone_name = azurerm_dns_zone.ky3owxyz.name
   ttl = "3600"
   records = [
      azurerm_public_ip.blogip.ip_address
   ]
}

resource "azurerm_dns_a_record" "wwwredirect" {
   name = "www"
   resource_group_name = azurerm_resource_group.blog.name
   zone_name = azurerm_dns_zone.ky3owxyz.name
   ttl = "3600"
   records = [
      azurerm_public_ip.blogip.ip_address
   ]
}

resource "azurerm_network_security_group" "blog" {
   name = "blog-nsg"
   resource_group_name = azurerm_resource_group.blog.name
   location = azurerm_resource_group.blog.location

   security_rule {
      name = "HTTP"
      priority = 1001
      direction = "Inbound"
      access = "Allow"
      protocol = "Tcp"
      source_port_range = "*"
      destination_port_range = "80"
      source_address_prefix = "*"
      destination_address_prefix = "*"
   }

   security_rule {
      name = "HTTPS"
      priority = 1002
      direction = "Inbound"
      access = "Allow"
      protocol = "Tcp"
      source_port_range = "*"
      destination_port_range = "443"
      source_address_prefix = "*"
      destination_address_prefix = "*"
   }

   security_rule {
      name = "SSH"
      priority = 1003
      direction = "Inbound"
      access = "Allow"
      protocol = "Tcp"
      source_port_range = "*"
      destination_port_range = "22"
      source_address_prefix = var.ssh_source_address_prefix
      destination_address_prefix = "*"
   }
}

resource "azurerm_subnet_network_security_group_association" "blog" {
   subnet_id = azurerm_subnet.blogsubnet.id
   network_security_group_id = azurerm_network_security_group.blog.id
}

output "vm_ips" {
   value = azurerm_linux_virtual_machine.blogvm.public_ip_address
}
