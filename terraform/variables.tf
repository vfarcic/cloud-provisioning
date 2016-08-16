variable "aws_access_key" {}
variable "aws_secret_key" {}
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

variable "jenkins_ami_id" {
  default = "unknown"
}
variable "jenkins" {
  default = {
    instance_type = "m3.medium"
    count         = "1"
    admin_user    = "admin"
    admin_pass    = "admin"
  }
}

variable "jenkins_agent_ami_id" {
  default = "unknown"
}

variable "jenkins_agent" {
  default = {
    instance_type = "t1.micro"
    count         = "2"
  }
}

variable "elk_ami_id" {
  default = "unknown"
}
variable "elk" {
  default = {
    instance_type = "m3.medium"
    count         = "1"
  }
}

variable "registry_ami_id" {
  default = "unknown"
}
variable "registry" {
  default = {
    instance_type = "t1.micro"
    count         = 1
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
