locals {
  action = local.node_count != 1 ? "Container will be destroyed: http://${var.dns-subdomain}.${var.dns-zone}" : "Container available: http://${var.dns-subdomain}.${var.dns-zone}"
  args = concat(var.args, ["--NotebookApp.custom_display_url=${var.dns-subdomain}.${var.dns-zone}:${var.external_port}"])
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
    name = "${var.app_name}-container"
    labels = {
      App = "${var.app_name}"
    }
  }
  spec {
    container {
      image = "${var.docker_image}"
      name  = "container"
      port {
        container_port = var.container_port
      }
      env {
        name = var.envs[0].name
        value = var.envs[0].value
        }
      env {
        name = var.envs[1].name
        value = var.envs[1].value
        }
      command = [var.command]
      args = local.args
      volume_mount {
        mount_path = "${var.mount_path}"
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
      port        = var.external_port
      target_port = var.container_port
    }
    type = "LoadBalancer"
  }
}

data "http" "report_pod_ip" {
  depends_on = [kubernetes_service.loadbalancer]
  url = "https://api.telegram.org/bot${var.bot_auth}/sendMessage?chat_id=${var.bot_chatid}&text=${urlencode(local.action)}"
}
