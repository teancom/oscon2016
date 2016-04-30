variable "organization" {
  default = "ACME"
}

variable "registry_cn" {
  default = "registry"
}

#################################
# CA certificate
#################################
resource "tls_self_signed_cert" "ca" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.ca.private_key_pem}"

  subject {
    common_name  = "simple ca"
    organization = "${var.organization}"
  }

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
  ]

  is_ca_certificate = true
}

resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

#################################
# registry certificate
#################################
resource "tls_locally_signed_cert" "registry" {
  cert_request_pem = "${tls_cert_request.registry.cert_request_pem}"

  ca_key_algorithm   = "RSA"
  ca_private_key_pem = "${tls_private_key.ca.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.ca.cert_pem}"

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

resource "tls_cert_request" "registry" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.registry.private_key_pem}"

  subject {
    common_name  = "${var.registry_cn}"
    organization = "${var.organization}"
  }
}

resource "tls_private_key" "registry" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

output "ca_pem" {
  value = "${tls_self_signed_cert.ca.cert_pem}"
}

output "registry_pem" {
  value = "${tls_locally_signed_cert.registry.cert_pem}"
}

output "registry_key_pem" {
  value = "${tls_private_key.registry.private_key_pem}"
}
