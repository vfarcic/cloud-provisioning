resource "digitalocean_ssh_key" "docker" {
  name = "devops21-do"
  public_key = "${file("devops21-do.public")}"
}