variable "resource-group" {
  default = ""
}

variable "prefix" {
  default = ""
}

variable "ssh" {
  default = ""
}

variable "admin" {
  default = "swarmadmin"
}

variable "vm_size_manager" {
  default = "Standard_D1"
}

variable "vm_size_worker" {
  default = "Standard_A2"
}

variable "manager-base-name" {
  default = "manager"
}

variable "worker-base-name" {
  default = "worker"
}

variable "resource-base-name" {
  default = ""
}