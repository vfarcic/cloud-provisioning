variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_default_region" {}
variable "swarm_manager_token" {
  default = ""
}
variable "swarm_worker_token" {
  default = ""
}
variable "swarm_ami_id" {
  default = "unknown"
}
variable "swarm_manager_ip" {
  default = ""
}
variable "swarm_managers" {
  default = 3
}
variable "swarm_workers" {
  default = 2
}
variable "swarm_instance_type" {
  default = "m3.medium"
}
variable "swarm_init" {
  default = false
}
variable "rexray" {
  default = false
}
variable "efs" {
  default = false
}
variable "ci_ami_id" {
  default = "unknown"
}
variable "ci_instance_type" {
  default = "m3.medium"
}
variable "ci_count" {
  default = 0
}
variable "test_swarm_managers" {
  default = 3
}
variable "test_swarm_workers" {
  default = 2
}
variable "test_swarm_instance_type" {
  default = "m3.medium"
}
variable "test_swarm_manager_token" {
  default = ""
}
variable "test_swarm_worker_token" {
  default = ""
}
variable "test_swarm_manager_ip" {
  default = ""
}
