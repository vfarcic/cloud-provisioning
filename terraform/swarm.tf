resource "aws_security_group" "vxlan" {
  name = "vxlan"
  description = "VXLAN traffic"
  vpc_id      = "${aws_vpc.devops.id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
  }

}

resource "aws_instance" "swarm-init" {
  ami = "${var.swarm_ami_id}"
  instance_type = "${var.swarm["instance_type"]}"
  tags {
    Name = "swarm-manager"
  }
  subnet_id = "${aws_subnet.devops.id}"
  vpc_security_group_ids = [
    "${aws_security_group.ssh.id}",
    "${aws_security_group.www.id}",
    "${aws_security_group.vxlan.id}",
    "${aws_vpc.devops.default_security_group_id}"
  ]
  depends_on = [
    "aws_route.internet_access",
    "aws_efs_mount_target.devops"
  ]
  key_name = "devops21"
  connection {
    user = "ubuntu"
    private_key = "${file("devops21.pem")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /data/",
      "sudo mount -t nfs4 -o nfsvers=4.1 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).${aws_efs_file_system.devops.id}.efs.${var.region}.amazonaws.com:/ /data/",
      "sudo mkdir -p /data/swarm",
      "docker swarm init --advertise-addr ${aws_instance.swarm-init.private_ip}",
      "docker swarm join-token -q worker | sudo tee /data/swarm/worker.token",
      "docker swarm join-token -q manager | sudo tee /data/swarm/manager.token",
      "sudo chmod 0400 /data/swarm/*.token"
    ]
  }
}

resource "aws_instance" "swarm-manager" {
  ami = "${var.swarm_ami_id}"
  count = "${var.swarm["count_managers"]}"
  instance_type = "${var.swarm["instance_type"]}"
  tags {
    Name = "swarm-manager"
  }
  subnet_id = "${aws_subnet.devops.id}"
  vpc_security_group_ids = [
    "${aws_security_group.ssh.id}",
    "${aws_security_group.www.id}",
    "${aws_security_group.vxlan.id}",
    "${aws_vpc.devops.default_security_group_id}"
  ]
  depends_on = [
    "aws_route.internet_access",
    "aws_efs_mount_target.devops",
    "aws_instance.swarm-init"
  ]
  key_name = "devops21"
  connection {
    user = "ubuntu"
    private_key = "${file("devops21.pem")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /data/",
      "sudo mount -t nfs4 -o nfsvers=4.1 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).${aws_efs_file_system.devops.id}.efs.${var.region}.amazonaws.com:/ /data/",
      "echo \"docker swarm join --token $(sudo cat /data/swarm/manager.token) --advertise-addr ${self.private_ip} ${aws_instance.swarm-init.private_ip}:2377\"",
      "docker swarm join --token $(sudo cat /data/swarm/manager.token) --advertise-addr ${self.private_ip} ${aws_instance.swarm-init.private_ip}:2377"
    ]
  }
}

resource "aws_instance" "swarm-worker" {
  ami = "${var.swarm_ami_id}"
  count = "${var.swarm["count_workers"]}"
  instance_type = "${var.swarm["instance_type"]}"
  tags {
    Name = "swarm-worker"
  }
  subnet_id = "${aws_subnet.devops.id}"
  vpc_security_group_ids = [
    "${aws_security_group.ssh.id}",
    "${aws_security_group.www.id}",
    "${aws_security_group.vxlan.id}",
    "${aws_vpc.devops.default_security_group_id}"
  ]
  depends_on = [
    "aws_route.internet_access",
    "aws_efs_mount_target.devops",
    "aws_instance.swarm-init"
  ]
  key_name = "devops21"
  connection {
    user = "ubuntu"
    private_key = "${file("devops21.pem")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /data/",
      "sudo mount -t nfs4 -o nfsvers=4.1 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).${aws_efs_file_system.devops.id}.efs.${var.region}.amazonaws.com:/ /data/",
      "sudo docker swarm join --token $(sudo cat /data/swarm/worker.token) --advertise-addr ${self.private_ip} ${aws_instance.swarm-init.private_ip}:2377"
    ]
  }
}

output "swarm_init_public_ip" {
  value = "${aws_instance.swarm-init.public_ip}"
}

output "swarm_init_private_ip" {
  value = "${aws_instance.swarm-init.private_ip}"
}

