resource "aws_instance" "jenkins" {
  count = "${var.jenkins.count}"
  ami = "${var.jenkins_ami_id}"
  instance_type = "${var.jenkins.instance_type}"
  tags {
    Name = "jenkins"
  }
  subnet_id = "${aws_subnet.devops.id}"
  vpc_security_group_ids = [
    "${aws_security_group.ssh.id}",
    "${aws_security_group.www.id}",
    "${aws_vpc.devops.default_security_group_id}"
  ]
  depends_on = ["aws_route.internet_access", "aws_efs_mount_target.devops"]
  key_name = "devops"
  connection {
    user = "ubuntu"
    private_key = "${file("devops.pem")}"
  }
  provisioner "remote-exec" {
    inline = [
      "docker-compose -f /composes/jenkins/docker-compose.yml down",
      "sudo mkdir -p /data",
      "sudo mount -t nfs4 -o nfsvers=4.1 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).${aws_efs_file_system.devops.id}.efs.${var.region}.amazonaws.com:/ /data/",
      "sudo mkdir -p /data/jenkins",
      "sudo chmod -R 777 /data/jenkins",
      "docker-compose -f /composes/jenkins/docker-compose.yml up -d"
    ]
  }
}

output "jenkins_public_ip" {
  value = "${aws_instance.jenkins.public_ip}"
}

output "jenkins_private_ip" {
  value = "${aws_instance.jenkins.private_ip}"
}

