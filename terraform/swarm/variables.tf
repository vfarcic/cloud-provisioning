variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "ami_id" {}
variable "region" {
  default = "us-west-2"
}
variable "ssh_user" {}
variable "ssh_pass" {}
variable "swarm_secret" {
  default = "my_secret"
}
variable "count_managers" {
  default = "2"
}
variable "count_agents" {
  default = "2"
}
variable "instance_type" {
  default = "t1.micro"
}
