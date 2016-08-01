resource "aws_instance" "swarm-init" {
  ami = "${var.swarm_ami_id}"
  instance_type = "${var.swarm.instance_type}"
  tags {
    Name = "docker-manager"
  }
  subnet_id = "${aws_subnet.devops.id}"
  vpc_security_group_ids = [
    "${aws_security_group.ssh.id}",
    "${aws_vpc.devops.default_security_group_id}"
  ]
  depends_on = [
    "aws_route.internet_access",
    "aws_efs_mount_target.devops",
    "aws_instance.registry"
  ]
  key_name = "devops"
  connection {
    user = "ubuntu"
    private_key = "${file("devops.pem")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/systemd/system/docker.service.d",
      "echo \"${template_file.swarm.rendered}\" | sudo tee /etc/systemd/system/docker.service.d/docker.conf",
      "sudo systemctl daemon-reload",
      "sudo service docker restart",
      "sudo mkdir /data/",
      "sudo mount -t nfs4 -o nfsvers=4.1 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).${aws_efs_file_system.devops.id}.efs.${var.region}.amazonaws.com:/ /data/",
      "sudo mkdir -p /data/swarm",
      "docker swarm init --advertise-addr ${aws_instance.swarm-init.private_ip} --listen-addr ${aws_instance.swarm-init.private_ip}:2377",
      "docker node update --label-add environment=production $(docker node inspect -f \"{{.ID}}\" self)",
      "docker swarm join-token -q worker | sudo tee /data/swarm/worker.token",
      "docker swarm join-token -q manager | sudo tee /data/swarm/manager.token",
      "sudo chmod 0400 /data/swarm/*.token"
    ]
  }
}

resource "aws_instance" "swarm-manager" {
  ami = "${var.swarm_ami_id}"
  count = "${var.swarm.count_managers}"
  instance_type = "${var.swarm.instance_type}"
  tags {
    Name = "docker-manager"
  }
  subnet_id = "${aws_subnet.devops.id}"
  vpc_security_group_ids = [
    "${aws_security_group.ssh.id}",
    "${aws_vpc.devops.default_security_group_id}"
  ]
  depends_on = [
    "aws_route.internet_access",
    "aws_efs_mount_target.devops",
    "aws_instance.swarm-init",
    "aws_instance.registry"
  ]
  key_name = "devops"
  connection {
    user = "ubuntu"
    private_key = "${file("devops.pem")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/systemd/system/docker.service.d",
      "echo \"${template_file.swarm.rendered}\" | sudo tee /etc/systemd/system/docker.service.d/docker.conf",
      "sudo systemctl daemon-reload",
      "sudo service docker restart",
      "sudo mkdir /data/",
      "sudo mount -t nfs4 -o nfsvers=4.1 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).${aws_efs_file_system.devops.id}.efs.${var.region}.amazonaws.com:/ /data/",
      "sudo docker swarm join --token $(sudo cat /data/swarm/manager.token) ${aws_instance.swarm-init.private_ip}:2377",
      "docker node update --label-add environment=production $(docker node inspect -f \"{{.ID}}\" self)"
    ]
  }
}

resource "aws_instance" "swarm-proxy" {
  ami = "${var.swarm_ami_id}"
  count = "${var.swarm.count_proxies}"
  instance_type = "${var.swarm.instance_type}"
  tags {
    Name = "docker-proxy"
  }
  subnet_id = "${aws_subnet.devops.id}"
  vpc_security_group_ids = [
    "${aws_security_group.ssh.id}",
    "${aws_security_group.www.id}",
    "${aws_vpc.devops.default_security_group_id}"
  ]
  depends_on = [
    "aws_route.internet_access",
    "aws_efs_mount_target.devops",
    "aws_instance.swarm-init",
    "aws_instance.registry"
  ]
  key_name = "devops"
  connection {
    user = "ubuntu"
    private_key = "${file("devops.pem")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/systemd/system/docker.service.d",
      "echo \"${template_file.swarm.rendered}\" | sudo tee /etc/systemd/system/docker.service.d/docker.conf",
      "sudo systemctl daemon-reload",
      "sudo service docker restart",
      "sudo mkdir /data/",
      "sudo mount -t nfs4 -o nfsvers=4.1 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).${aws_efs_file_system.devops.id}.efs.${var.region}.amazonaws.com:/ /data/",
      "sudo docker swarm join --token $(sudo cat /data/swarm/manager.token) ${aws_instance.swarm-init.private_ip}:2377",
      "docker node update --label-add environment=proxy $(docker node inspect -f \"{{.ID}}\" self)",
      "docker node demote $(docker node inspect -f \"{{.ID}}\" self)"
    ]
  }
}

resource "aws_instance" "swarm-worker" {
  ami = "${var.swarm_ami_id}"
  count = "${var.swarm.count_workers}"
  instance_type = "${var.swarm.instance_type}"
  tags {
    Name = "docker-worker"
  }
  subnet_id = "${aws_subnet.devops.id}"
  vpc_security_group_ids = [
    "${aws_security_group.ssh.id}",
    "${aws_vpc.devops.default_security_group_id}"
  ]
  depends_on = [
    "aws_route.internet_access",
    "aws_efs_mount_target.devops",
    "aws_instance.swarm-init",
    "aws_instance.registry"
  ]
  key_name = "devops"
  connection {
    user = "ubuntu"
    private_key = "${file("devops.pem")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/systemd/system/docker.service.d",
      "echo \"${template_file.swarm.rendered}\" | sudo tee /etc/systemd/system/docker.service.d/docker.conf",
      "sudo systemctl daemon-reload",
      "sudo service docker restart",
      "sudo mkdir /data/",
      "sudo mount -t nfs4 -o nfsvers=4.1 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).${aws_efs_file_system.devops.id}.efs.${var.region}.amazonaws.com:/ /data/",
      "sudo docker swarm join --token $(sudo cat /data/swarm/manager.token) ${aws_instance.swarm-init.private_ip}:2377",
      "docker node update --label-add environment=production $(docker node inspect -f \"{{.ID}}\" self)",
      "docker node demote $(docker node inspect -f \"{{.ID}}\" self)"
    ]
  }
}

resource "aws_instance" "swarm-test" {
  ami = "${var.swarm_ami_id}"
  count = "${var.swarm.count_tests}"
  instance_type = "${var.swarm.instance_type}"
  tags {
    Name = "docker-test"
  }
  subnet_id = "${aws_subnet.devops.id}"
  vpc_security_group_ids = [
    "${aws_security_group.ssh.id}",
    "${aws_security_group.www.id}",
    "${aws_vpc.devops.default_security_group_id}"
  ]
  depends_on = [
    "aws_route.internet_access",
    "aws_efs_mount_target.devops",
    "aws_instance.swarm-init",
    "aws_instance.registry"
  ]
  key_name = "devops"
  connection {
    user = "ubuntu"
    private_key = "${file("devops.pem")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/systemd/system/docker.service.d",
      "echo \"${template_file.swarm.rendered}\" | sudo tee /etc/systemd/system/docker.service.d/docker.conf",
      "sudo systemctl daemon-reload",
      "sudo service docker restart",
      "sudo mkdir /data/",
      "sudo mount -t nfs4 -o nfsvers=4.1 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).${aws_efs_file_system.devops.id}.efs.${var.region}.amazonaws.com:/ /data/",
      "sudo docker swarm join --token $(sudo cat /data/swarm/manager.token) ${aws_instance.swarm-init.private_ip}:2377",
      "docker node update --label-add environment=test $(docker node inspect -f \"{{.ID}}\" self)",
      "docker node demote $(docker node inspect -f \"{{.ID}}\" self)"
    ]
  }
}

resource "template_file" "swarm" {
  template = "${file("conf/docker.cfg")}"

  vars {
    registry_private_ip = "${aws_instance.registry.private_ip}"
  }
}


output "public_ip_swarm_init" {
  value = "${aws_instance.swarm-init.public_ip}"
}

output "private_ip_swarm_init" {
  value = "${aws_instance.swarm-init.private_ip}"
}

output "public_ip_swarm_test" {
  value = "${aws_instance.swarm-test.public_ip}"
}

output "private_ip_swarm_test" {
  value = "${aws_instance.swarm-test.private_ip}"
}

output "public_ip_swarm_proxy" {
  value = "${aws_instance.swarm-proxy.public_ip}"
}

output "private_ip_swarm_proxy" {
  value = "${aws_instance.swarm-proxy.private_ip}"
}
