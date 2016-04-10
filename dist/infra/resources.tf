resource "digitalocean_droplet" "app" {
  image = "${var.image}"
  name = "app.${var.project}"
  region = "${var.region}"
  size = "${var.app_size}"
  private_networking = true
  ssh_keys = [
    "${var.ssh_fingerprint}"
  ]
  user_data = "${template_file.user_data.rendered}"

  connection {
    user = "${var.user}"
    type = "ssh"
    key_file = "${var.private_key}"
    timeout = "2m"
  }
}

resource "digitalocean_record" "app" {
  domain = "${var.domain}"
  type = "A"
  name = "${digitalocean_droplet.app.name}"
  value = "${digitalocean_droplet.app.ipv4_address}"
}

resource "digitalocean_droplet" "swarm" {
  count = "${var.swarm_count}"
  image = "${var.image}"
  name = "swarm-${count.index+1}.${var.project}"
  region = "${var.region}"
  size = "${var.swarm_size}"
  private_networking = true
  ssh_keys = [
    "${var.ssh_fingerprint}"
  ]
  user_data = "${template_file.user_data.rendered}"

  connection {
    user = "${var.user}"
    type = "ssh"
    key_file = "${var.private_key}"
    timeout = "2m"
  }
}

resource "digitalocean_record" "swarm" {
  count = "${var.swarm_count}"
  domain = "${var.domain}"
  type = "A"
  name = "${element(digitalocean_droplet.swarm.*.name, count.index)}"
  value = "${element(digitalocean_droplet.swarm.*.ipv4_address, count.index)}"
}

resource "template_file" "user_data" {
  template = "${file("${path.module}/conf/cloud-config.yaml")}"

  vars {
    public_key = "${var.public_key}"
    user = "${var.user}"

  }
}