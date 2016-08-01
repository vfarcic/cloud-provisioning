resource "aws_instance" "elk" {
  count = "${var.elk.count}"
  ami = "${var.elk_ami_id}"
  instance_type = "${var.elk.instance_type}"
  tags {
    Name = "ELK"
  }
  subnet_id = "${aws_subnet.devops.id}"
  vpc_security_group_ids = [
    "${aws_security_group.ssh.id}",
    "${aws_security_group.www.id}",
    "${aws_vpc.devops.default_security_group_id}"
  ]
  depends_on = ["aws_route.internet_access"]
}

output "elk_public_ip" {
  value = "${aws_instance.elk.public_ip}"
}

output "elk_private_ip" {
  value = "${aws_instance.elk.private_ip}"
}

