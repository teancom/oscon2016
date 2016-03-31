variable "do_token" {}
variable "private_key_path" {}
variable "ssh_key_id" {}
variable "region" {}
variable "public_key" {}

provider "digitalocean" {
  token = "${var.do_token}"
}

