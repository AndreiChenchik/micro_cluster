locals {
  action = local.node_count != 1 ? "Container will be destroyed: http://${var.dns-subdomain}.${var.dns-zone}" : "Container available: http://${var.dns-subdomain}.${var.dns-zone}"
}

resource "google_dns_record_set" "a-record" {
  count = local.node_count != 1 ? 0 : 1
  
  name = "${var.dns-subdomain}.${var.dns-zone}."
  type = "A"
  ttl  = 60

  managed_zone = "${var.dns-zone-name}"

  rrdatas = ["${kubernetes_service.loadbalancer[0].load_balancer_ingress[0].ip}"]
}

resource "kubernetes_pod" "container" {
  count = local.node_count != 1 ? 0 : 1
  
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
      volume_mount {
        mount_path = "/test"
        name = "persistent-volume"
      }
    }
    
    volume {
      name= "persistent-volume"
      gce_persistent_disk {
        pd_name = "${var.persistent-disk-name}"
      }
    }
  }
}

resource "kubernetes_service" "loadbalancer" {
  count = local.node_count != 1 ? 0 : 1
  
  depends_on = [kubernetes_pod.container]
  metadata {
    name = "loadbalancer"
  }
  spec {
    selector = {
      App = kubernetes_pod.container[0].metadata[0].labels.App
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}

data "http" "report_pod_ip" {
  depends_on = [kubernetes_service.loadbalancer]
  url = "https://api.telegram.org/bot${var.bot_auth}/sendMessage?chat_id=${var.bot_chatid}&text=${urlencode(local.action)}"
}
