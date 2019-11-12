provider "acme" {
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = "${tls_private_key.private_key.private_key_pem}"
  email_address   = "${var.email}"
}

resource "acme_certificate" "certificate" {
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
    "tls.crt" = "${acme_certificate.certificate.certificate_pem}"
    "tls.key" = "${acme_certificate.certificate.private_key_pem}"
  }
}

resource "google_compute_address" "static" {
  count = local.node_count != 1 ? 0 : 1
  
  name = "ipv4-address"
}

resource "kubernetes_ingress" "ingress" {
  count = local.node_count != 1 ? 0 : 1

  metadata {
    name = "container-ingress"
    
    annotations = {
      "kubernetes.io/ingress.global-static-ip-name" = "${google_compute_address.static[0].name}"
    }
  }

  spec {
    backend {
      service_name = kubernetes_service.proxy[0].metadata.0.name
      service_port = 8888
      }
    
    tls {
      secret_name = "tls-cert"
    }
  }
}
