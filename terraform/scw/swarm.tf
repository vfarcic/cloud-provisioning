provider "scaleway" {
  region       = "${var.region}"
}

data "scaleway_image" "ubuntu" {
  architecture = "x86_64"
  name = "Ubuntu Xenial"
}

# Choose Docker-ready kernel
data "scaleway_bootscript" "docker" {
  architecture = "x86_64"
  name_filter = "docker"
}

# Floating/elastic IP for manager access
resource "scaleway_ip" "manager_ip" {
  server = "${scaleway_server.manager.0.id}"
}

resource "scaleway_server" "manager" {
  count = "${var.managers}"
  name = "swarm-manager-${count.index}"
  image = "${data.scaleway_image.ubuntu.id}"
  bootscript = "${data.scaleway_bootscript.docker.id}"
  type = "${var.instance_type}"
  dynamic_ip_required = "true"
  provisioner "remote-exec" {
    inline = [
      "curl -sSL https://get.docker.com/ | sh",
      "if   ${var.swarm_init}; then docker swarm init --advertise-addr ${self.private_ip}; fi",
      "if ! ${var.swarm_init}; then docker swarm join --token ${var.swarm_manager_token} --advertise-addr ${self.private_ip} ${var.swarm_manager_ip}:2377; fi"
    ]
  }
}

resource "scaleway_server" "worker" {
  count = "${var.workers}"
  name = "swarm-worker-${count.index}"
  image = "${data.scaleway_image.ubuntu.id}"
  bootscript = "${data.scaleway_bootscript.docker.id}"
  type = "${var.instance_type}"
  dynamic_ip_required = "true"
  provisioner "remote-exec" {
    inline = [
      "curl -sSL https://get.docker.com/ | sh",
      "docker swarm join --token ${var.swarm_worker_token} --advertise-addr ${self.private_ip} ${var.swarm_manager_ip}:2377"
    ]
  }
}

output "manager_external" {
  value = "${scaleway_ip.manager_ip.ip}"
}

output "manager_internal" {
  value = "${scaleway_server.manager.0.private_ip}"
}
