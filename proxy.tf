resource "kubernetes_service" "proxy" {
  count = local.node_count != 1 ? 0 : 1

  metadata {
    name      = "container-proxy"
  }

  spec {
    type             = "NodePort"

    port {
      name        = "http"
      protocol    = "TCP"
      port        = var.container_port
      target_port = var.container_port
    }

    selector = {
      app = kubernetes_pod.container[0].metadata[0].labels.App
    }
  }
}

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
    rule {
      host = "${var.dns-subdomain}.${var.dns-zone}"
      http {
        path {
          backend {
            service_name = kubernetes_service.proxy[0].metadata.0.name
            service_port = var.container_port
            }
          }
        }
      }
    
    tls {
      secret_name = "tls-cert"
    }
  }
}
