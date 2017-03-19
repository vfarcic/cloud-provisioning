variable "instance_type" {
  default = "VC1S"
}
variable "region" {
  default = "ams1"
}
variable "managers" {
  default = "1"
}
variable "workers" {
  default = "3"
}
variable "swarm_init" {
  default = "false"
}
variable "swarm_manager_ip" {
    default = ""
}
variable "swarm_manager_token" {
    default = ""
}
variable "swarm_worker_token" {
    default = ""
}
