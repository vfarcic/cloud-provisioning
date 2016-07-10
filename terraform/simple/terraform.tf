provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.region}"
}

resource "aws_instance" "example" {
    ami = "ami-b628c9db"
    instance_type = "t1.micro"
}