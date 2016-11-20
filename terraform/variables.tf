variable "aws_access_key" {
  default = ""
}
variable "aws_secret_key" {
  default = ""
}
variable "region" {
  default = "us-east-1"
}
variable "manager_token" {
  default = ""
}
variable "worker_token" {
  default = ""
}
variable "swarm_ami_id" {
  default = "unknown"
}
variable "swarm" {
  default = {
    instance_type      = "t1.micro"
    count_managers     = "2"
    count_workers      = "2"
  }
}
