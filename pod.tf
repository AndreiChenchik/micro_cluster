locals {
  action = tonumber(chomp(file("${path.module}/node_count"))) != 1 ? "Container will be destroyed: http://" : "Container available: http://"
}

resource "kubernetes_pod" "nginx" {
  depends_on = [google_container_node_pool.nodes]
  metadata {
    name = "nginx-example"
    labels = {
      App = "nginx"
    }
  }
  spec {
    container {
      image = "nginx:1.7.8"
      name  = "example"
      port {
        container_port = 80
      }
    }
  }
}
resource "kubernetes_service" "nginx" {
  depends_on = [kubernetes_pod.nginx]
  metadata {
    name = "nginx-example"
  }
  spec {
    selector = {
      App = kubernetes_pod.nginx.metadata[0].labels.App
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}

data "http" "report_pod_ip" {
  depends_on = [kubernetes_service.nginx]
  url = "https://api.telegram.org/bot${var.bot_auth}/sendMessage?chat_id=${var.bot_chatid}&text=${urlencode(local.action)}"${kubernetes_service.nginx.load_balancer_ingress[0].ip}"
}

