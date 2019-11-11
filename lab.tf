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
  name     = "my-gke-cluster"
  location = "us-central1"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  location   = "us-central1"
  cluster    = "${google_container_cluster.primary.name}"
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}
*/
