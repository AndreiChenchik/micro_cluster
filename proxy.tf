resource "kubernetes_ingress" "ingress" {
  count = local.node_count != 1 ? 0 : 1

  metadata {
    name = "container-ingress"
    
    annotations = {
      "kubernetes.io/ingress.global-static-ip-name" = "${google_compute_global_address.static[0].name}"
    }
  }

  spec {
    rule {
      host = "${var.dns-subdomain}.${var.dns-zone}"
      http {
        path {
          backend {
            service_name = "container-nodeport"
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

resource "kubernetes_service" "ingress-nginx" {
  count = local.node_count != 1 ? 0 : 1
  
  metadata {
    name = "ingress-nginx"
    namespace = "ingress-nginx"
  }
  spec {
    external_traffic_policy = "Local"
    selector = {
      "app.kubernetes.io/name" = "ingress-nginx"
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
    port {
      name = "http"
      port = 80
      target_port = "http"
    }

    port {
      name = "https"
      port = 443
      target_port = "https"
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_service" "nodeport" {
  count = local.node_count != 1 ? 0 : 1
  
  metadata {
    name = "container-nodeport"
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
