resource "aws_instance" "ci" {
  count = "${var.ci_count}"
  ami = "${var.ci_ami_id}"
  instance_type = "${var.ci_instance_type}"
  tags {
    Name = "ci"
  }
  vpc_security_group_ids = [
    "${aws_security_group.docker.id}"
  ]
  key_name = "devops21"
  connection {
    user = "ubuntu"
    private_key = "${file("devops21.pem")}"
  }
}

output "ci_public_ip" {
  value = "${aws_instance.ci.0.public_ip}"
}

