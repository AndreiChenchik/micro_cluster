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

  rrdatas = ["${kubernetes_service.ingress[0].load_balancer_ingress[0].ip}"]
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

resource "google_compute_managed_ssl_certificate" "container" {
  count = local.node_count != 1 ? 0 : 1

  provider = "google-beta"

  name = "container-ssl"

  managed {
    domains = ["{var.dns-subdomain}.${var.dns-zone}"]
  }
}


resource "kubernetes_service" "proxy" {
  count = local.node_count != 1 ? 0 : 1

  metadata {
    namespace = "default"
    name      = kubernetes_deployment.proxy_dep.metadata.0.name
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

resource "kubernetes_ingress" "ingress" {
  count = local.node_count != 1 ? 0 : 1

  metadata {
    name = "container-ingress"

    annotations = {
      "ingress.gcp.kubernetes.io/pre-shared-cert"   = google_compute_managed_ssl_certificate.container[0].name
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.address.name
    }
  }

  spec {
    rule {
      http {
        path {
          backend {
            service_name = kubernetes_service.proxy[0].metadata.0.name
            service_port = 80
          }
        }
      }
    }
  }
}

data "http" "report_pod_ip" {
  depends_on = [kubernetes_service.loadbalancer]
  url = "https://api.telegram.org/bot${var.bot_auth}/sendMessage?chat_id=${var.bot_chatid}&text=${urlencode(local.action)}"
}
