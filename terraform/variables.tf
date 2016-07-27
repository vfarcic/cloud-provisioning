variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "ssh_user" {}
variable "ssh_pass" {}
variable "region" {
  default = "us-west-2"
}
variable "jenkins_ami_id" {
  default = "unknown"
}
variable "jenkins_agent_ami_id" {
  default = "unknown"
}
variable "jenkins" {
  default = {
    instance_type = "m3.large"
    count         = "1"
    admin_user    = "admin"
    admin_pass    = "admin"
  }
}

variable "jenkins_agent" {
  default = {
    instance_type = "t1.micro"
    count         = "2"
  }
}