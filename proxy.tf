resource "kubernetes_service" "loadbalancer" {
  count = local.node_count != 1 ? 0 : 1
  
  metadata {
    name = "${kubernetes_pod.container[0].metadata.0.labels.app}"
  }
  spec {
    load_balancer_ip = "${google_compute_global_address.static[0].address}"
    selector = {
      app = "${kubernetes_pod.container[0].metadata.0.labels.app}"
    }
    port {
      port = var.external_port
      target_port = var.container_port
    }

  type = "LoadBalancer"
  }
}
