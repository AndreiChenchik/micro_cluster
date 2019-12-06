# preload config files
locals {
  node_count = tonumber(chomp(file("${path.module}/node_count")))
  node_type = chomp(file("${path.module}/node_type"))
}

# auth to google cloud
provider "google" {
 credentials = var.credentials
 project     = "${var.project_id}"
 region      = "${var.region}"
 zone        = "${var.zone}"
}

# create cluster
resource "google_container_cluster" "primary" {
  name     = "${var.cluster_name}"
  location = "${var.zone}"

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

# create node pool
resource "google_container_node_pool" "nodes" {
  name       = "${var.pool_name}"
  location   = "${var.zone}"
  cluster    = "${google_container_cluster.primary.name}"
  node_count = local.node_count

  node_config {
    preemptible  = true
    machine_type = local.node_type

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

# query my Terraform service account from GCP
data "google_client_config" "current" {}

# define provider
provider "kubernetes" {
  load_config_file = false
  host = "https://${google_container_cluster.primary.endpoint}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)}"
  token = "${data.google_client_config.current.access_token}"
}

# deploy jupyter
module "jupyter" {
  source = "git@github.com:gumlooter/dockerized_jupyter.git"
  module_count = local.node_count
  node_pool = google_container_node_pool.nodes
  persistent_disk = var.persistent-disk-name
  external_port = 443
  public_url = "https://${var.dns_subdomain}.${var.dns-zone}"
  password = var.jupyter_password
}
  
# assign dns name  
resource "google_dns_record_set" "a-record" {
  # only if running
  count = local.node_count != 1 ? 0 : 1
  
  name = "${var.dns-subdomain}.${var.dns-zone}."
  type = "A"
  ttl  = 60
  managed_zone = "${var.dns-zone-name}"
  rrdatas = ["${module.jupyter.kubernetes_service.jupyter_loadbalancer[0].load_balancer_ingress.0.ip}"]
}
