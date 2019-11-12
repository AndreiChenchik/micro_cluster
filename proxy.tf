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
      hosts = ["${var.dns-subdomain}.${var.dns-zone}"]
      secret_name = "tls-cert"
    }
  }
  depends_on = [kubernetes_service.nodeport]
}


resource "kubernetes_service" "nodeport" {
  metadata {
    name = "container-nodeport"
  }
  spec {
    selector = {
      #app = "${kubernetes_pod.container[0].metadata.0.labels.app}"
    }
    port {
      port = var.container_port
    }

    type = "NodePort"
  }
}
