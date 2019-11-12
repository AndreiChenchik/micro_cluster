locals {
  action = local.node_count != 1 ? "Container will be destroyed: http://${var.dns-subdomain}.${var.dns-zone}" : "Container available: http://${var.dns-subdomain}.${var.dns-zone}"
  args = concat(var.args, ["--NotebookApp.custom_display_url=${var.dns-subdomain}.${var.dns-zone}:${var.external_port}","--NotebookApp.password=${var.jupyter_password}"])
  }

resource "google_dns_record_set" "a-record" {
  count = local.node_count != 1 ? 0 : 1
  
  name = "${var.dns-subdomain}.${var.dns-zone}."
  type = "A"
  ttl  = 60

  managed_zone = "${var.dns-zone-name}"

  rrdatas = ["${google_compute_address.static[0].address}"]
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

resource "kubernetes_service" "proxy" {
  count = local.node_count != 1 ? 0 : 1

  metadata {
    namespace = "default"
    name      = "container-proxy"
  }

  spec {
    type             = "NodePort"
    session_affinity = "ClientIP"

    port {
      name        = "http"
      protocol    = "TCP"
      port        = 80
      target_port = 8888
    }

    selector = {
      app = kubernetes_pod.container[0].metadata[0].labels.App
    }
  }
}

data "http" "report_pod_ip" {
  depends_on = [kubernetes_ingress.ingress]
  url = "https://api.telegram.org/bot${var.bot_auth}/sendMessage?chat_id=${var.bot_chatid}&text=${urlencode(local.action)}"
}
