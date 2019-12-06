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
  
# get pool nodes info
data "google_compute_instance_group" "pool_info" {
  depends_on = [google_container_node_pool.nodes]
  
  count = local.node_count != 1 ? 0 : 1

  self_link = google_container_cluster.primary.instance_group_urls[0]
}

# workaround to iterate over instances
locals {                                                            
  nodes_string = local.node_count != 1 ? "," : join(",", data.google_compute_instance_group.pool_info[0].instances)
  nodes_list = split(",", local.nodes_string) 
}  
 
# get first node info
data "google_compute_instance" "node_info" {
  depends_on = [google_container_node_pool.nodes]
  
  count = local.node_count != 1 ? 0 : 1
  self_link = local.nodes_list[0]
}

# expose nodeport to external network
resource "google_compute_firewall" "default" {  
  count = local.node_count != 1 ? 0 : 1
  
  depends_on = [google_container_node_pool.nodes]
 
  name    = "nodeport-firewall"
  network = google_container_cluster.primary.network

  allow {
    protocol = "tcp"
    ports    = [var.jupyter_port]
  }
}

# get node ip
locals {                                                            
  ip = data.google_compute_instance.node_info != [] ? data.google_compute_instance.node_info[0].network_interface[0].access_config[0].nat_ip : "127.0.0.1"
}  

# reserve ip
resource "google_compute_address" "ip_address" {
  count = local.node_count != 1 ? 0 : 1
  
  address = local.ip
  name = "my-address"
}
  
# assign dns name  
resource "google_dns_record_set" "a-record" {
  # only if running
  count = local.node_count != 1 ? 0 : 1
  
  name = "${var.dns-subdomain}.${var.dns-zone}."
  type = "A"
  ttl  = 60
  managed_zone = var.dns-zone-name
  rrdatas = [local.ip]
}
