variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "ami_id" {}
variable "region" {
  default = "us-east-1"
}
variable "instance_type" {
  default = "t1.micro"
}