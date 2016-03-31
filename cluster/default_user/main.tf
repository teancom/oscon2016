variable "default_user" {
  default = "centos"
}

variable "public_key" {}

resource "template_file" "user_data" {
  template = "${file("${path.module}/conf/cloud-config.yaml")}"
  
  vars {
    public_key = "${var.public_key}"
    user = "${var.default_user}"
  }  
}

output "cloud_config" {
  value = "${template_file.user_data.rendered}"
}