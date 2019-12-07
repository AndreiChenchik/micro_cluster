# preload config files
locals {
  node_count = tonumber(chomp(file("${path.module}/node_count")))
  node_type = chomp(file("${path.module}/node_type"))
}

# auth to google cloud
provider "google" {
 credentials = var.credentials
 project     = var.project_id
 region      = var.region
 zone        = var.zone
}

# create cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone

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
  name       = var.pool_name
  location   = var.zone
  cluster    = google_container_cluster.primary.name
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
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
  token = data.google_client_config.current.access_token
}

# deploy jupyter
module "jupyter" {
  source = "github.com/gumlooter/dockerized_jupyter"
  module_count = local.node_count
  node_pool = google_container_node_pool.nodes
  persistent_disk = var.persistent-disk-name
  external_port = var.jupyter_port
  public_url = "https://${var.dns-subdomain}.${var.dns-zone}:${var.jupyter_port}"
  password = var.jupyter_password
}

# deploy postgres
module "postgres" {
  source = "./postgres"
  module_count = local.node_count
  node_pool = google_container_node_pool.nodes
  persistent_disk = var.postgres_disk
  external_port = var.postgres_port
  user = var.postgres_user
  password = var.postgres_password
}

# deploy code-server
module "code-server" {
  source = "./code-server"
  module_count = 1 # 0 to turn it off
  node_pool = google_container_node_pool.nodes
  persistent_disk = var.coder_disk
  external_port = var.coder_port
  additional_ports = var.coder_additional_ports
  password = var.coder_password
}

# combine all ports
locals {
  external_ports = concat([var.jupyter_port, var.postgres_port, var.coder_port], split(",", var.coder_additional_ports))         
}

# expose nodeport to external network
resource "google_compute_firewall" "default" {  
  count = local.node_count != 1 ? 0 : 1
  
  depends_on = [google_container_node_pool.nodes]
 
  name    = "nodeport-firewall-${formatdate("YYYYMMDDhhss", timestamp())}"
  network = google_container_cluster.primary.network

  allow {
    protocol = "tcp"
    ports    = local.external_ports
  }
}

# deploy dns assigner
module "libcloud-dynamic-dns" {
  source = "github.com/gumlooter/libcloud-dynamic-dns"
  module_count = local.node_count # 0 to turn it off
  node_pool = google_container_node_pool.nodes
  persistent_disk = var.ddns-config-disk
}
