locals {
  action = local.node_count != 1 ? "Container no up" : "Container available: https://${var.dns-subdomain}.${var.dns-zone}"
  args = concat(var.args, ["--NotebookApp.custom_display_url=https://${var.dns-subdomain}.${var.dns-zone}","--NotebookApp.password=${var.jupyter_password}"])
  }

resource "kubernetes_pod" "container" {
  count = local.node_count != 1 ? 0 : 1
  
  depends_on = [google_container_node_pool.nodes]
  metadata {
    name = "${var.app_name}"
    labels = {
      app = "${var.app_name}"
    }
  }
  spec {
    container {
      image = "${var.docker_image}"
      name = "${var.app_name}"
      port {
        container_port = var.container_port
      }
      env {
        name = var.envs[0].name
        value = var.envs[0].value
        }
      command = [var.command]
      args = local.args
      volume_mount {
        mount_path = "${var.mount_path}"
        name = "persistent-volume"
      }
      
      resources {
        limits {
          cpu = "800m"
          memory = "32Gi"
        }
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

data "http" "report_pod_ip" {
  depends_on = [kubernetes_service.loadbalancer]
  url = "https://api.telegram.org/bot${var.bot_auth}/sendMessage?chat_id=${var.bot_chatid}&text=${urlencode(local.action)}"
}
