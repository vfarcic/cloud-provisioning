resource "aws_instance" "test-swarm-manager" {
  count = "${var.test_swarm_managers}"
  ami = "${var.swarm_ami_id}"
  instance_type = "${var.test_swarm_instance_type}"
  tags {
    Name = "test-swarm-manager"
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
      "if ${var.swarm_init}; then docker swarm init --advertise-addr ${self.private_ip}; fi",
      "if ! ${var.swarm_init}; then docker swarm join --token ${var.test_swarm_manager_token} --advertise-addr ${self.private_ip} ${var.test_swarm_manager_ip}:2377; fi",
      "if ${var.rexray}; then echo \"${data.template_file.rexray.rendered}\" | sudo tee /etc/rexray/config.yml; fi",
      "if ${var.rexray}; then sudo rexray service start >/dev/null 2>/dev/null; fi"
    ]
  }
}

resource "aws_instance" "test-swarm-worker" {
  count = "${var.test_swarm_workers}"
  ami = "${var.swarm_ami_id}"
  instance_type = "${var.test_swarm_instance_type}"
  tags {
    Name = "test-swarm-worker"
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
      "docker swarm join --token ${var.test_swarm_worker_token} --advertise-addr ${self.private_ip} ${var.test_swarm_manager_ip}:2377",
      "if ${var.rexray}; then echo \"${data.template_file.rexray.rendered}\" | sudo tee /etc/rexray/config.yml; fi",
      "if ${var.rexray}; then sudo rexray service start >/dev/null 2>/dev/null; fi"
    ]
  }
}

output "test_swarm_manager_1_public_ip" {
  value = "${aws_instance.test-swarm-manager.0.public_ip}"
}

output "test_swarm_manager_1_private_ip" {
  value = "${aws_instance.test-swarm-manager.0.private_ip}"
}

output "test_swarm_manager_2_public_ip" {
  value = "${aws_instance.test-swarm-manager.1.public_ip}"
}

output "test_swarm_manager_2_private_ip" {
  value = "${aws_instance.test-swarm-manager.1.private_ip}"
}

output "test_swarm_manager_3_public_ip" {
  value = "${aws_instance.test-swarm-manager.2.public_ip}"
}

output "test_swarm_manager_3_private_ip" {
  value = "${aws_instance.test-swarm-manager.2.private_ip}"
}

