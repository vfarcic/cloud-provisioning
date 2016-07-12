provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.region}"
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "registry" {
  name = "registry"
  description = "SSH and Internet traffic"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_instance" "registry" {
  count = "2"
  ami = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  tags {
    Name = "registry"
  }
  subnet_id = "${aws_subnet.default.id}"
  vpc_security_group_ids = ["${aws_security_group.registry.id}", "${aws_vpc.default.default_security_group_id}"]
}

resource "aws_efs_file_system" "devops" {
  reference_name = "devops"
  tags {
    Name = "DevOps"
  }
}

resource "aws_efs_mount_target" "default" {
  file_system_id = "${aws_efs_file_system.devops.id}"
  subnet_id = "${aws_subnet.default.id}"
//  security_groups = ["${aws_security_group.default.id}"]
}

output "public_dns" {
  value = "${aws_instance.registry.public_dns}"
}

output "public_ip" {
  value = "${aws_instance.registry.public_ip}"
}

output "private_ip" {
  value = "${aws_instance.registry.private_ip}"
}

output "efs_id" {
  value = "${aws_efs_file_system.devops.id}"
}
