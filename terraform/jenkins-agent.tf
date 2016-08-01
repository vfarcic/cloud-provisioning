resource "aws_instance" "jenkins_agent" {
  count = "${var.jenkins_agent.count}"
  ami = "${var.jenkins_agent_ami_id}"
  instance_type = "${var.jenkins_agent.instance_type}"
  tags {
    Name = "jenkins-agent"
  }
  subnet_id = "${aws_subnet.devops.id}"
  vpc_security_group_ids = [
    "${aws_security_group.ssh.id}",
    "${aws_vpc.devops.default_security_group_id}"
  ]
  depends_on = ["aws_route.internet_access", "aws_instance.jenkins"]
  provisioner "remote-exec" {
    connection {
      user = "ubuntu"
      private_key = "${file("devops.pem")}"
    }
    inline = [
      "nohup java -jar /var/lib/swarm-client-2.2-jar-with-dependencies.jar -master http://${aws_instance.jenkins.private_ip} -labels \"docker java ubuntu linux\" -username ${var.jenkins.admin_user} -password ${var.jenkins.admin_pass} >/tmp/jenkins_agent.log 2>&1 &"
    ]
  }
}

output "jenkins_agent_public_ip" {
  value = "${aws_instance.jenkins_agent.public_ip}"
}

output "jenkins_agent_private_ip" {
  value = "${aws_instance.jenkins_agent.private_ip}"
}

