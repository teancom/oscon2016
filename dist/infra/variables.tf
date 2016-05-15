variable "project" {
}

variable "confbot_webhook_url" {
}

variable "domain" {
}

variable "public_key" {
}

variable "image" {
  default = "ubuntu-14-04-x64"
}

variable "region" {
}

variable "user" {
  default = "workshop"
}

variable "app_size" {
  default = "4gb"
}

variable "swarm_size" {
  default = "4gb"
}

variable "swarm_count" {
  default = "3"
}
