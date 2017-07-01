# Configure the Microsoft Azure Provider
#provider "azurerm" {
#  subscription_id = "..."
#  client_id       = "..."
#  client_secret   = "..."
#  tenant_id       = "..."
#}

resource "azurerm_resource_group" "swarm" {
  name     = "swarm-terraform-acs"
  location = "${var.location}"
}

resource "azurerm_container_service" "swarm" {
  name                   = "acctestcontservice1"
  location               = "${azurerm_resource_group.swarm.location}"
  resource_group_name    = "${azurerm_resource_group.swarm.name}"
  orchestration_platform = "Swarm"

  master_profile {
    count      = "${var.swarm_managers}"
    dns_prefix = "${var.personal_prefix}-swarm-manager"
  }

  linux_profile {
    admin_username = "swarmadmin"

    ssh_key {
      key_data = "${var.swarm_manager_token}"
    }
  }

  agent_pool_profile {
    name       = "swarmworkers"
    count      = "${var.swarm_workers}"
    dns_prefix = "${var.personal_prefix}-swarm-agent"
    vm_size    = "${var.swarm_worker_type}"
  }

  diagnostics_profile {
    enabled = false
  }

}