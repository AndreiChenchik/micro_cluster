resource "kubernetes_ingress" "ingress" {
  count = local.node_count != 1 ? 0 : 1

  metadata {
    name = "container-ingress"
    
    annotations = {
      "kubernetes.io/ingress.global-static-ip-name" = "${google_compute_global_address.static[0].name}"
      "ingress.kubernetes.io/force-ssl-redirect" = "true"
    }
  }

  spec {
    backend {
      service_name = "${var.app_name}"
      service_port = var.container_port
      }
    
    tls {
      secret_name = "tls-cert"
    }
  }
}
