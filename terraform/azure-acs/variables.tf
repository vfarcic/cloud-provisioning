variable "swarm_manager_token" {
  default = ""
}

variable "swarm_worker_token" {
  default = ""
}

variable "swarm_managers" {
  default = 3
}
variable "swarm_workers" {
  default = 2
}

variable "swarm_worker_type" {
  default = "Standard_A1"
}

variable "personal_prefix" {
  default = ""
}

variable "location" {
  default = "West Europe"
}