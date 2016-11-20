resource "aws_instance" "swarm-init" {
  ami = "${var.swarm_ami_id}"
  instance_type = "${var.swarm["instance_type"]}"
  tags {
    Name = "swarm-manager"
  }
  vpc_security_group_ids = [
    "${aws_security_group.docker.id}"
  ]
  key_name = "devops21"
  connection {
    user = "ubuntu"
    private_key = "${file("devops21.pem")}"
  }
  provisioner "remote-exec" {
    inline = [
      "docker swarm init --advertise-addr ${aws_instance.swarm-init.private_ip}"
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
  vpc_security_group_ids = [
    "${aws_security_group.docker.id}"
  ]
  depends_on = [
    "aws_instance.swarm-init"
  ]
  key_name = "devops21"
  connection {
    user = "ubuntu"
    private_key = "${file("devops21.pem")}"
  }
  provisioner "remote-exec" {
    inline = [
      "echo \"docker swarm join --token ${var.manager_token} --advertise-addr ${self.private_ip} ${aws_instance.swarm-init.private_ip}:2377\"",
      "docker swarm join --token ${var.manager_token} --advertise-addr ${self.private_ip} ${aws_instance.swarm-init.private_ip}:2377"
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
  vpc_security_group_ids = [
    "${aws_security_group.docker.id}"
  ]
  depends_on = [
    "aws_instance.swarm-init"
  ]
  key_name = "devops21"
  connection {
    user = "ubuntu"
    private_key = "${file("devops21.pem")}"
  }
  provisioner "remote-exec" {
    inline = [
      "echo \"docker swarm join --token ${var.worker_token} --advertise-addr ${self.private_ip} ${aws_instance.swarm-init.private_ip}:2377\"",
      "docker swarm join --token ${var.worker_token} --advertise-addr ${self.private_ip} ${aws_instance.swarm-init.private_ip}:2377"
    ]
  }
}

output "swarm_manager_1_public_ip" {
  value = "${aws_instance.swarm-init.public_ip}"
}

output "swarm_manager_1_private_ip" {
  value = "${aws_instance.swarm-init.private_ip}"
}

output "swarm_manager_2_public_ip" {
  value = "${aws_instance.swarm-manager.0.public_ip}"
}

output "swarm_manager_2_private_ip" {
  value = "${aws_instance.swarm-manager.0.private_ip}"
}

output "swarm_manager_3_public_ip" {
  value = "${aws_instance.swarm-manager.1.public_ip}"
}

output "swarm_manager_3_private_ip" {
  value = "${aws_instance.swarm-manager.1.private_ip}"
}

