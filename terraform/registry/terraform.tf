provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.region}"
}

resource "aws_instance" "registry" {
  ami = "${var.ami_id}"
  instance_type = "m3.large"
  tags {
    Name = "registry"
  }
  security_groups = ["${aws_security_group.registry.name}"]
}

resource "aws_security_group" "registry" {
  name = "registry"
  description = "SSH and Internet traffic"

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

output "public_dns" {
  value = "${aws_instance.registry.public_dns}"
}

output "public_ip" {
  value = "${aws_instance.registry.public_ip}"
}

output "private_ip" {
  value = "${aws_instance.registry.private_ip}"
}
