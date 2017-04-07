resource "azurerm_resource_group" "swarm" {
  name     = "${var.resource-group}"
  location = "West Europe"
}

resource "azurerm_virtual_network" "swarm" {
  name                = "drove"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.swarm.location}"
  resource_group_name = "${azurerm_resource_group.swarm.name}"
}

resource "azurerm_storage_account" "swarm" {
  name                = "${var.prefix}dockervolumes"
  resource_group_name = "${azurerm_resource_group.swarm.name}"
  location            = "${azurerm_resource_group.swarm.location}"
  account_type        = "Standard_GRS"
}

resource "azurerm_subnet" "swarm" {
  name                 = "drovesub"
  resource_group_name  = "${azurerm_resource_group.swarm.name}"
  virtual_network_name = "${azurerm_virtual_network.swarm.name}"
  address_prefix       = "10.0.3.0/24"
}


##############################################
##############################################
######## LOAD BALANCER
##############################################
##############################################
resource "azurerm_public_ip" "swarmmanagerlbip" {
  name                         = "${var.prefix}swarmmanagerlbip"
  location                     = "${azurerm_resource_group.swarm.location}"
  resource_group_name          = "${azurerm_resource_group.swarm.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_lb" "swarmmanagerlb" {
  name                = "${var.resource-base-name}loadbalancer"
  location            = "${azurerm_resource_group.swarm.location}"
  resource_group_name = "${azurerm_resource_group.swarm.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.swarmmanagerlbip.id}"
  }
}

resource "azurerm_lb_probe" "probessh" {
  resource_group_name = "${azurerm_resource_group.swarm.name}"
  loadbalancer_id     = "${azurerm_lb.swarmmanagerlb.id}"
  name                = "LBProbe22"
  port                = 22
}


resource "azurerm_lb_probe" "probehttps" {
  resource_group_name = "${azurerm_resource_group.swarm.name}"
  loadbalancer_id     = "${azurerm_lb.swarmmanagerlb.id}"
  name                = "LBProbe443"
  port                = 443
}

## BACKEND POOL VM1
resource "azurerm_lb_backend_address_pool" "manager1" {
  resource_group_name = "${azurerm_resource_group.swarm.name}"
  loadbalancer_id     = "${azurerm_lb.swarmmanagerlb.id}"
  name                = "LBBackendPoolManager1"
}

## BACKEND POOL VM2
resource "azurerm_lb_backend_address_pool" "manager2" {
  resource_group_name = "${azurerm_resource_group.swarm.name}"
  loadbalancer_id     = "${azurerm_lb.swarmmanagerlb.id}"
  name                = "LBBackendPoolWorker1"
}

## BACKEND POOL AVSET
resource "azurerm_lb_backend_address_pool" "avset" {
  resource_group_name = "${azurerm_resource_group.swarm.name}"
  loadbalancer_id     = "${azurerm_lb.swarmmanagerlb.id}"
  name                = "LBBackendPoolAVSET"
}

##############################################
##############################################

##############################################
##############################################
######## VM AVAILABILITY SET
##############################################
##############################################

resource "azurerm_availability_set" "avset" {
  name                = "${var.resource-base-name}avset"
  location            = "${azurerm_resource_group.swarm.location}"
  resource_group_name = "${azurerm_resource_group.swarm.name}"
}

##############################################
##############################################
##############################################
##############################################
########### V M 's ###########################
## Each VM has:
# Public IP (via NIC)
# NIC
# Storage Account (via S.A. Container)
# Storage Account Container (For VHD)
# Part of a Availability Set
# Docker Extension

##############################################
######## SWARM - MANAGERS
######## MANAGER1
##############################################

# NIC - Network Interface
resource "azurerm_network_interface" "nic-manager1" {
  name                = "${var.resource-base-name}nicmanager1"
  location            = "${azurerm_resource_group.swarm.location}"
  resource_group_name = "${azurerm_resource_group.swarm.name}"

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = "${azurerm_subnet.swarm.id}"
    private_ip_address_allocation = "dynamic"
  }
}

# Storage account
resource "azurerm_storage_account" "sa-manager1" {
  name                = "${var.prefix}samanager1"
  resource_group_name = "${azurerm_resource_group.swarm.name}"
  location            = "${azurerm_resource_group.swarm.location}"
  account_type        = "Standard_GRS"
}

# Storage Account Container
resource "azurerm_storage_container" "sc-manager1" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.swarm.name}"
  storage_account_name  = "${azurerm_storage_account.sa-manager1.name}"
  container_access_type = "private"
}

# VM
resource "azurerm_virtual_machine" "vm-manager1" {
  name                  = "vm-manager1"
  location              = "${azurerm_resource_group.swarm.location}"
  resource_group_name   = "${azurerm_resource_group.swarm.name}"
  network_interface_ids = ["${azurerm_network_interface.nic-manager1.id}"]
  vm_size               = "${var.vm_size_manager}"
  availability_set_id   = "${azurerm_availability_set.avset.id}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "myosdisk1"
    vhd_uri       = "${azurerm_storage_account.sa-manager1.primary_blob_endpoint}${azurerm_storage_container.sc-manager1.name}/myosdisk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "manager1"
    admin_username = "${var.admin}"
    admin_password = "fRLCuek67V1g"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin}/.ssh/authorized_keys"
      key_data = "${var.ssh}"
    }
  }
}

## VM Extension
resource "azurerm_virtual_machine_extension" "vm-manager1-ext" {
  name                       = "hostname"
  location                   = "${azurerm_resource_group.swarm.location}"
  resource_group_name        = "${azurerm_resource_group.swarm.name}"
  virtual_machine_name       = "${azurerm_virtual_machine.vm-manager1.name}"
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "DockerExtension"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

##############################################
##############################################
######## SWARM - WORKERS
######## WORKER1
##############################################

# NIC - Network Interface
resource "azurerm_network_interface" "nic-worker1" {
  name                = "${var.resource-base-name}nic${var.worker-base-name}1"
  location            = "${azurerm_resource_group.swarm.location}"
  resource_group_name = "${azurerm_resource_group.swarm.name}"

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = "${azurerm_subnet.swarm.id}"
    private_ip_address_allocation = "dynamic"
  }
}

# Storage account
resource "azurerm_storage_account" "sa-worker1" {
  name                = "${var.prefix}${var.resource-base-name}sa${var.worker-base-name}1"
  resource_group_name = "${azurerm_resource_group.swarm.name}"
  location            = "${azurerm_resource_group.swarm.location}"
  account_type        = "Standard_GRS"
}

# Storage Account Container
resource "azurerm_storage_container" "sc-worker1" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.swarm.name}"
  storage_account_name  = "${azurerm_storage_account.sa-worker1.name}"
  container_access_type = "private"
}

# VM
resource "azurerm_virtual_machine" "vm-worker1" {
  name                  = "${var.resource-base-name}vm${var.worker-base-name}1"
  location              = "${azurerm_resource_group.swarm.location}"
  resource_group_name   = "${azurerm_resource_group.swarm.name}"
  network_interface_ids = ["${azurerm_network_interface.nic-worker1.id}"]
  vm_size               = "${var.vm_size_worker}"
  availability_set_id   = "${azurerm_availability_set.avset.id}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "myosdisk1"
    vhd_uri       = "${azurerm_storage_account.sa-worker1.primary_blob_endpoint}${azurerm_storage_container.sc-worker1.name}/myosdisk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.worker-base-name}1"
    admin_username = "${var.admin}"
    admin_password = "fRLCuek67V1g"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin}/.ssh/authorized_keys"
      key_data = "${var.ssh}"
    }
  }
}

## VM Extension
resource "azurerm_virtual_machine_extension" "vm-worker1-ext" {
  name                       = "hostname"
  location                   = "${azurerm_resource_group.swarm.location}"
  resource_group_name        = "${azurerm_resource_group.swarm.name}"
  virtual_machine_name       = "${azurerm_virtual_machine.vm-worker1.name}"
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "DockerExtension"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

##############################################
######## WORKER2
##############################################

# NIC - Network Interface
resource "azurerm_network_interface" "nic-worker2" {
  name                = "${var.resource-base-name}nic${var.worker-base-name}2"
  location            = "${azurerm_resource_group.swarm.location}"
  resource_group_name = "${azurerm_resource_group.swarm.name}"

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = "${azurerm_subnet.swarm.id}"
    private_ip_address_allocation = "dynamic"
  }
}

# Storage account
resource "azurerm_storage_account" "sa-worker2" {
  name                = "${var.prefix}${var.resource-base-name}sa${var.worker-base-name}2"
  resource_group_name = "${azurerm_resource_group.swarm.name}"
  location            = "${azurerm_resource_group.swarm.location}"
  account_type        = "Standard_GRS"
}

# Storage Account Container
resource "azurerm_storage_container" "sc-worker2" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.swarm.name}"
  storage_account_name  = "${azurerm_storage_account.sa-worker2.name}"
  container_access_type = "private"
}

# VM
resource "azurerm_virtual_machine" "vm-worker2" {
  name                  = "${var.resource-base-name}vm${var.worker-base-name}2"
  location              = "${azurerm_resource_group.swarm.location}"
  resource_group_name   = "${azurerm_resource_group.swarm.name}"
  network_interface_ids = ["${azurerm_network_interface.nic-worker2.id}"]
  vm_size               = "${var.vm_size_worker}"
  availability_set_id   = "${azurerm_availability_set.avset.id}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "myosdisk1"
    vhd_uri       = "${azurerm_storage_account.sa-worker2.primary_blob_endpoint}${azurerm_storage_container.sc-worker2.name}/myosdisk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.worker-base-name}2"
    admin_username = "${var.admin}"
    admin_password = "fRLCuek67V1g"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin}/.ssh/authorized_keys"
      key_data = "${var.ssh}"
    }
  }
}

## VM Extension
resource "azurerm_virtual_machine_extension" "vm-worker2-ext" {
  name                       = "hostname"
  location                   = "${azurerm_resource_group.swarm.location}"
  resource_group_name        = "${azurerm_resource_group.swarm.name}"
  virtual_machine_name       = "${azurerm_virtual_machine.vm-worker2.name}"
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "DockerExtension"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

##############################################
##############################################

