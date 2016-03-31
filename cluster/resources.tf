variable "project" {}
variable "domain" {}

variable "ssh_timeout" {
  default = "1m"
}

variable "image" {
  default = "centos-7-0-x64"
}

variable "master_count" {
  default = "1"
}

variable "minion_count" {
  default = "2"
}

variable "user" {
  default = "centos"
}

module "default_user" {
  source = "./default_user"

  default_user = "${var.user}"
  public_key = "${var.public_key}"
}

module "ca" {
  source = "./ca"

  registry_cn = "registry.${var.project}.${var.domain}"
}

resource "digitalocean_droplet" "master" {
  count = "${var.master_count}"
  image = "${var.image}"
  name = "k8s-master-${count.index+1}.${var.project}"
  region = "${var.region}"
  size = "4gb"
  private_networking = true
  ssh_keys = [
    "${var.ssh_key_id}"
  ]
  user_data = "${template_cloudinit_config.config.rendered}"

  connection {
    user = "${var.user}"
    type = "ssh"
    key_file = "${var.private_key_path}"
    timeout = "${var.ssh_timeout}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/Defaults    requiretty/Defaults    !requiretty/g' /etc/sudoers\n"
    ]
  }
}

resource "digitalocean_record" "master" {
  count = "${var.master_count}"
  domain = "${var.domain}"
  type = "A"
  name = "${element(digitalocean_droplet.master.*.name, count.index)}"
  value = "${element(digitalocean_droplet.master.*.ipv4_address, count.index)}"
}

resource "digitalocean_droplet" "minion" {
  count = "${var.minion_count}"
  image = "${var.image}"
  name = "k8s-minion-${count.index+1}.${var.project}"
  region = "${var.region}"
  size = "4gb"
  private_networking = true
  ssh_keys = [
    "${var.ssh_key_id}"
  ]
  user_data = "${template_cloudinit_config.config.rendered}"

  connection {
    user = "${var.user}"
    type = "ssh"
    key_file = "${var.private_key_path}"
    timeout = "${var.ssh_timeout}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/Defaults    requiretty/Defaults    !requiretty/g' /etc/sudoers\n"
    ]
  }
}

resource "digitalocean_record" "minion" {
  count = "${var.minion_count}"
  domain = "${var.domain}"
  type = "A"
  name = "${element(digitalocean_droplet.minion.*.name, count.index)}"
  value = "${element(digitalocean_droplet.minion.*.ipv4_address, count.index)}"
}

resource "digitalocean_droplet" "registry" {
  image = "${var.image}"
  name = "registry.${var.project}"
  region = "${var.region}"
  size = "4gb"
  private_networking = true
  ssh_keys = [
    "${var.ssh_key_id}"
  ]
  user_data = "${template_cloudinit_config.config.rendered}"

  connection {
    user = "${var.user}"
    type = "ssh"
    key_file = "${var.private_key_path}"
    timeout = "${var.ssh_timeout}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/Defaults    requiretty/Defaults    !requiretty/g' /etc/sudoers\n"
    ]
  }

  provisioner "local-exec" {
    command = "mkdir -p files"
  }

  provisioner "local-exec" {
    command = "echo '${module.ca.ca_pem}' > files/ca.pem"
  }

  provisioner "local-exec" {
    command = "echo '${module.ca.registry_pem}' > files/registry.pem"
  }

  provisioner "local-exec" {
    command = "echo '${module.ca.registry_key_pem}' > files/registry_key.pem"
  }
}

resource "digitalocean_record" "registry" {
  domain = "${var.domain}"
  type = "A"
  name = "${digitalocean_droplet.registry.name}"
  value = "${digitalocean_droplet.registry.ipv4_address}"
}

resource "digitalocean_droplet" "shell" {
  image = "${var.image}"
  name = "shell.${var.project}"
  region = "${var.region}"
  size = "4gb"
  private_networking = true
  ssh_keys = [
    "${var.ssh_key_id}"
  ]
  user_data = "${template_cloudinit_config.config.rendered}"

  connection {
    user = "${var.user}"
    type = "ssh"
    key_file = "${var.private_key_path}"
    timeout = "${var.ssh_timeout}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/Defaults    requiretty/Defaults    !requiretty/g' /etc/sudoers\n"
    ]
  }
}

resource "digitalocean_record" "shell" {
  domain = "${var.domain}"
  type = "A"
  name = "${digitalocean_droplet.shell.name}"
  value = "${digitalocean_droplet.shell.ipv4_address}"
}

resource "null_resource" "cluster" {
  provisioner "local-exec" {
    command = "mkdir -p group_vars"
  }

  provisioner "local-exec" {
    command = "rm -f group_vars/all"
  }

  provisioner "local-exec" {
    command = "echo \"cluster_project: ${var.project}\ncluster_domain: ${var.domain}\naccess_token: ${var.do_token}\" > group_vars/all"
  }
}

resource "template_cloudinit_config" "config" {
  gzip = false
  base64_encode = false

  part {
    content = "${module.default_user.cloud_config}"
  }
}

