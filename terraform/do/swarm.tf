resource "digitalocean_droplet" "swarm-manager" {
  count = "${var.swarm_managers}"
  image = "${var.swarm_image}"
  name = "${format("swarm-manager-%02d", count.index)}"
  region = "${var.swarm_region}"
  size = "${var.swarm_instance_size}"
  private_networking = true
  ssh_keys = [
    "${digitalocean_ssh_key.docker.id}"
  ]
  connection {
    user = "root"
    private_key = "${file("devops21-do")}"
    agent = false
  }
  provisioner "remote-exec" {
    inline = [
      "if ${var.swarm_init}; then docker swarm init --advertise-addr ${self.ipv4_address_private}; fi",
      "if ! ${var.swarm_init}; then docker swarm join --token ${var.swarm_manager_token} --advertise-addr ${self.ipv4_address_private} ${var.swarm_manager_ip}:2377; fi"
    ]
  }
}

output "swarm_manager_1_public_ip" {
  value = "${digitalocean_droplet.swarm-manager.0.ipv4_address}"
}

output "swarm_manager_1_private_ip" {
  value = "${digitalocean_droplet.swarm-manager.0.ipv4_address_private}"
}

output "swarm_manager_2_public_ip" {
  value = "${digitalocean_droplet.swarm-manager.1.ipv4_address}"
}

output "swarm_manager_2_private_ip" {
  value = "${digitalocean_droplet.swarm-manager.1.ipv4_address_private}"
}

output "swarm_manager_3_public_ip" {
  value = "${digitalocean_droplet.swarm-manager.2.ipv4_address}"
}

output "swarm_manager_3_private_ip" {
  value = "${digitalocean_droplet.swarm-manager.2.ipv4_address_private}"
}