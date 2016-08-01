resource "aws_security_group" "registry" {
  name = "registry"
  description = "Docker Registry traffic"
  vpc_id      = "${aws_vpc.devops.id}"

  ingress {
    from_port = 5000
    to_port = 5000
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
  count = "${var.registry.count}"
  ami = "${var.registry_ami_id}"
  instance_type = "${var.registry.instance_type}"
  tags {
    Name = "registry"
  }
  subnet_id = "${aws_subnet.devops.id}"
  vpc_security_group_ids = [
    "${aws_security_group.ssh.id}",
    "${aws_security_group.registry.id}",
    "${aws_vpc.devops.default_security_group_id}"
  ]
  depends_on = ["aws_route.internet_access", "aws_efs_mount_target.devops"]
  key_name = "devops"
  provisioner "remote-exec" {
    connection {
      user = "ubuntu"
      private_key = "${file("devops.pem")}"
    }
    inline = [
      "sudo mkdir -p /data/",
      "sudo mount -t nfs4 -o nfsvers=4.1 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).${aws_efs_file_system.devops.id}.efs.${var.region}.amazonaws.com:/ /data/",
      "sudo mkdir -p /data/registry"
    ]
  }
}

output "registry_public_ip" {
  value = "${aws_instance.registry.public_ip}"
}

output "registry_private_ip" {
  value = "${aws_instance.registry.private_ip}"
}
