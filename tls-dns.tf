provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = "${tls_private_key.private_key.private_key_pem}"
  email_address   = "${var.email}"
}

resource "acme_certificate" "cert" {
  account_key_pem           = "${acme_registration.reg.account_key_pem}"
  common_name               = "${var.dns-subdomain}.${var.dns-zone}"

  dns_challenge {
    provider = "gcloud"
    
    config = {
      GCE_PROJECT = "${var.project_id}"
      GCE_SERVICE_ACCOUNT = "${var.credentials}"
      }
  }
}

resource "kubernetes_secret" "tls-secret" {
  type  = "kubernetes.io/tls"

  metadata {
    name      = "tls-cert"
  }

  data = {
    "tls.crt" = "${acme_certificate.cert.certificate_pem}"
    "tls.key" = "${acme_certificate.cert.private_key_pem}"
  }
}

resource "google_dns_record_set" "a-record" {
  count = local.node_count != 1 ? 0 : 1
  
  name = "${var.dns-subdomain}.${var.dns-zone}."
  type = "A"
  ttl  = 60

  managed_zone = "${var.dns-zone-name}"

  rrdatas = ["${kubernetes_service.loadbalancer[0].load_balancer_ingress.0.ip}"]
}
