resource "aws_instance" "base" {
  ami = "${var.base_ami_id}"
  instance_type = "${var.base.instance_type}"
  tags {
    Name = "base"
  }
  subnet_id = "${aws_subnet.devops.id}"
  vpc_security_group_ids = [
    "${aws_security_group.ssh.id}",
    "${aws_security_group.www.id}",
    "${aws_vpc.devops.default_security_group_id}"
  ]
  depends_on = ["aws_route.internet_access"]
  key_name = "devops"
  connection {
    user = "ubuntu"
    private_key = "${file("devops.pem")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /data/",
      "sudo mount -t nfs4 -o nfsvers=4.1 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).${aws_efs_file_system.devops.id}.efs.${var.region}.amazonaws.com:/ /data/",
    ]
  }
}

output "base_public_ip" {
  value = "${aws_instance.base.public_ip}"
}

output "base_private_ip" {
  value = "${aws_instance.base.private_ip}"
}

