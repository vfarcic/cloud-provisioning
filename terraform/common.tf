provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.region}"
}

resource "aws_vpc" "devops" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "devops" {
  vpc_id = "${aws_vpc.devops.id}"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.devops.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.devops.id}"
}

resource "aws_subnet" "devops" {
  vpc_id                  = "${aws_vpc.devops.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${var.availability_zone}"
}

resource "aws_security_group" "ssh" {
  name = "ssh"
  description = "SSH traffic"
  vpc_id      = "${aws_vpc.devops.id}"

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

resource "aws_security_group" "www" {
  name = "www"
  description = "Web traffic"
  vpc_id      = "${aws_vpc.devops.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
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


resource "aws_efs_file_system" "devops" {
  reference_name = "devops"
  tags {
    Name = "devops"
  }
}

resource "aws_efs_mount_target" "devops" {
  file_system_id = "${aws_efs_file_system.devops.id}"
  subnet_id = "${aws_subnet.devops.id}"
}