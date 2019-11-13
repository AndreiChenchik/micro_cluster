resource "kubernetes_ingress" "ingress" {
  count = local.node_count != 1 ? 0 : 1

  metadata {
    name = "${kubernetes_pod.container[0].metadata.0.labels.app}"
    
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
          path = "/"
          backend {
            service_name = "${kubernetes_pod.container[0].metadata.0.labels.app}"
            service_port = var.container_port
            }
          }
        }
      }
    
    tls {
      hosts = ["${var.dns-subdomain}.${var.dns-zone}"]
      secret_name = "tls-cert"
    }
  }
  depends_on = [kubernetes_service.nodeport]
}


resource "kubernetes_service" "nodeport" {
  count = local.node_count != 1 ? 0 : 1
  
  metadata {
    name = "${kubernetes_pod.container[0].metadata.0.labels.app}"
  }
  spec {
    selector = {
      app = "${kubernetes_pod.container[0].metadata.0.labels.app}"
    }
    port {
      port = var.container_port
    }

  type = "NodePort"
  }
}
