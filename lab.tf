variable "credentials" {
}

variable "bot_auth" {
}

variable "bot_chatid" {
}

variable "project_id" {
}

variable "region" {
}

variable "zone" {
}

variable "instance_name" {
}

data "http" "report_terraforming" {
  	url = "https://api.telegram.org/bot${var.bot_auth}/sendMessage?chat_id=${var.bot_chatid}&text=Terraforming%20Started"
}

provider "google" {
 credentials = var.credentials
 project     = "${var.project_id}"
 region      = "${var.region}"
 zone        = "${var.zone}"
}
/*
resource "google_compute_instance" "vm_instance" {
  name         = "${var.instance_name}"
  #machine_type = "g1-small"
  machine_type = "f1-micro"
  allow_stopping_for_update = true
 
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network       = "default"
    access_config {
    }
  }
}


data "http" "report_instance_ip" {
		depends_on = [google_compute_instance.vm_instance]
  	url = "https://api.telegram.org/bot${var.bot_auth}/sendMessage?chat_id=${var.bot_chatid}&text=Instance%20IP%20${google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip}"
}



resource "google_container_cluster" "primary" {
  name               = "my-gke-cluster"
  location           = "${var.zone}"
  initial_node_count = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  node_config {
    machine_type = "g1-small"
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

# Query my Terraform service account from GCP
data "google_client_config" "current" {}

provider "kubernetes" {
  load_config_file = false
  host = "https://${google_container_cluster.primary.endpoint}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)}"
  token = "${data.google_client_config.current.access_token}"
}

resource "kubernetes_pod" "nginx" {
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
  url = "https://api.telegram.org/bot${var.bot_auth}/sendMessage?chat_id=${var.bot_chatid}&text=Pod%20URL%20http%3A%2F%2F${kubernetes_service.nginx.load_balancer_ingress[0].ip}"
}
*/
