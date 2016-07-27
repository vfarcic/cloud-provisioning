variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "ami_id" {}
variable "ssh_user" {}
variable "ssh_pass" {}
variable "region" {
  default = "us-west-2"
}
variable "instance_type" {
  default = "t1.micro"
}
variable "count" {
  default = "1"
}