resource "kubernetes_service" "loadbalancer" {
  count = local.node_count != 1 ? 0 : 1
  
  metadata {
    name = "${kubernetes_pod.container[0].metadata.0.labels.app}"
  }
  
  spec {
    selector = {
      app = "${kubernetes_pod.container[0].metadata.0.labels.app}"
    }
    
    port {
      name = "jupyter"
      port = var.external_port
      target_port = var.container_port
    }
    
    port {
      name = "tensorboard"
      port = var.tensorboard_port
      target_port = var.tensorboard_port
    }
    
    type = "LoadBalancer"
  }
  
}


resource "kubernetes_service" "nodeport" {
  count = local.node_count != 1 ? 0 : 1
  
  metadata {
    name = "caddy"
  }
  
  spec {
    selector = {
      app = "caddy"
    }
    
    port {
      name = "caddy"
      port = var.caddy_port
      target_port = var.caddy_port
      node_port = var.caddy_port
    }
    
    type = "NodePort"
  }
  
}
