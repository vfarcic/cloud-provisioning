variable "aws_access_key" {
  default = ""
}
variable "aws_secret_key" {
  default = ""
}
variable "region" {
  default = "us-east-1"
}
variable "availability_zone" {
  default = "us-east-1b" # t1.micro is not available in all zones
}

variable "base_ami_id" {
  default = "unknown"
}
variable "base" {
  default = {
    instance_type = "t1.micro"
  }
}

variable "swarm_ami_id" {
  default = "unknown"
}
variable "swarm" {
  default = {
    instance_type      = "t1.micro"
    count_managers     = "2"
    count_proxies      = "1"
    count_workers      = "2"
    count_test_workers = "1"
  }
}
