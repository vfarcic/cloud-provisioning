provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.region}"
}

resource "aws_instance" "swarm-init" {
  ami = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  provisioner "remote-exec" {
    connection {
      user = "${var.ssh_user}"
      password = "${var.ssh_pass}"
    }
    inline = [
      "docker swarm init --listen-addr ${aws_instance.swarm-init.private_ip}:2377 --secret ${var.swarm_secret} --auto-accept manager --auto-accept worker"
    ]
  }
  tags {
    Name = "docker-manager"
  }
  security_groups = [
    "${aws_security_group.all.name}",
    "${aws_security_group.ssh.name}",
    "${aws_security_group.proxy.name}"
  ]
}

resource "aws_instance" "swarm-manager" {
  ami = "${var.ami_id}"
  count = "${var.managers}"
  instance_type = "${var.instance_type}"
  provisioner "remote-exec" {
    connection {
      user = "${var.ssh_user}"
      password = "${var.ssh_pass}"
    }
    inline = [
      "docker swarm join --manager ${aws_instance.swarm-init.private_ip}:2377 --secret ${var.swarm_secret}"
    ]
  }
  tags {
    Name = "docker-manager"
  }
  security_groups = [
    "${aws_security_group.all.name}",
    "${aws_security_group.ssh.name}",
    "${aws_security_group.proxy.name}"
  ]
}

resource "aws_instance" "swarm-agent" {
  ami = "${var.ami_id}"
  count = "${var.agents}"
  instance_type = "${var.instance_type}"
  provisioner "remote-exec" {
    connection {
      user = "${var.ssh_user}"
      password = "${var.ssh_pass}"
    }
    inline = [
      "docker swarm join ${aws_instance.swarm-init.private_ip}:2377 --secret ${var.swarm_secret}"
    ]
  }
  tags {
    Name = "docker-agent"
  }
  security_groups = [
    "${aws_security_group.all.name}",
    "${aws_security_group.ssh.name}",
    "${aws_security_group.proxy.name}"
  ]
}

resource "aws_security_group" "all" {
  name = "all"
  description = "All traffic"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "ssh" {
  name = "ssh"
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

resource "aws_security_group" "proxy" {
  name = "proxy"
  description = "Proxy HTTP and HTTPS traffic"

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

  ingress {
    from_port = 2377
    to_port = 2377
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

output "public_dns_swarm_init" {
  value = "${aws_instance.swarm-init.public_dns}"
}

output "public_ip_swarm_init" {
  value = "${aws_instance.swarm-init.public_ip}"
}

output "private_ip_swarm_init" {
  value = "${aws_instance.swarm-init.private_ip}"
}

output "public_ip_swarm_init" {
  value = "${aws_instance.swarm-init.public_ip}"
}
