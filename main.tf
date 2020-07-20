# preload config files
locals {
    node_count  = tonumber(chomp(file("${path.module}/node_count")))
    node_type   = chomp(file("${path.module}/node_type"))
}

# auth to google cloud
provider "google" {
 credentials    = var.credentials
 project        = var.project_id
 region         = var.region
 zone           = var.zone
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
    load_config_file        = false
    host                    = "https://${google_container_cluster.primary.endpoint}"
    cluster_ca_certificate  = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
    token                   = data.google_client_config.current.access_token
}

# deploy jupyter
module "jupyter" {
    source          = "github.com/gumlooter/dockerized_jupyter"
    module_count    = local.node_count
    node_pool       = google_container_node_pool.nodes
    persistent_disk = var.persistent-disk-name
    external_port   = var.jupyter_port
    public_url      = "https://${var.dns-subdomain}.${var.dns-zone}:${var.jupyter_port}"
    password        = var.jupyter_password
    cert            = acme_certificate.cert.certificate_pem
    cert_key        = acme_certificate.cert.private_key_pem
}

# deploy postgres
module "postgres" {
    source          = "./postgres"
    module_count    = local.node_count
    node_pool       = google_container_node_pool.nodes
    persistent_disk = var.postgres_disk
    password        = var.postgres_password
}

# deploy code-server
module "coder" {
    source              = "./code-server"
    module_count        = 1 # 0 to turn it off
    node_pool           = google_container_node_pool.nodes
    persistent_disk     = var.coder_disk
    external_port       = var.coder_port
    additional_ports    = var.coder_additional_ports
    password            = var.coder_password
    cert                = acme_certificate.cert.certificate_pem
    cert_key            = acme_certificate.cert.private_key_pem
}

# deploy finance-automation
module "finance-automation" {
    source              = "./finance-automation"
    module_count        = 1 # 0 to turn it off
    node_pool           = google_container_node_pool.nodes
    external_port       = var.finance_port
    dockerconfigjson    = var.dockerconfigjson
}
    
# deploy telegram bot: kudrin
module "kudrin" {
    source                  = "./kudrin"
    module_count            = 1 # 0 to turn it off
    node_pool               = google_container_node_pool.nodes
    kudrin-telegram_token   = var.kudrin-telegram_token
    kudrin-notion_token     = var.kudrin-notion_token
    kudrin-credit_limit     = var.kudrin-credit_limit
    kudrin-power_user_name  = var.kudrin-power_user_name
    kudrin-power_user_id    = var.kudrin-power_user_id
}

# deploy bitwarden password manager
module "bitwarden" {
    source                              = "./bitwarden"
    module_count                        = 1 # 0 to turn it off
    node_pool                           = google_container_node_pool.nodes
    bitwarden-installation_id           = var.bitwarden-installation_id
    bitwarden-installation_key          = var.bitwarden-installation_key
    bitwarden-identity_cert_password    = var.bitwarden-identity_cert_password
    bitwarden-mssql_password            = var.bitwarden-mssql_password
    bitwarden-identity_key              = var.bitwarden-identity_key
    bitwarden-duo_key                   = var.bitwarden-duo_key 
    bitwarden-reply_to                  = var.email 
    bitwarden-cert                      = join("", [acme_certificate.cert.certificate_pem, acme_certificate.cert.issuer_pem])
    bitwarden-cert_key                  = acme_certificate.cert.private_key_pem
    bitwarden-cert_ca                   = acme_certificate.cert.issuer_pem
    bitwarden-host                      = "${var.dns-subdomain}.${var.dns-zone}"
    bitwarden-port                      = var.bitwarden-port
    bitwarden-smtp_host                 = var.bitwarden-smtp_host
    bitwarden-smtp_port                 = var.bitwarden-smtp_port
    bitwarden-smtp_ssl                  = var.bitwarden-smtp_ssl
    bitwarden-smtp_username             = var.bitwarden-smtp_username
    bitwarden-smtp_password             = var.bitwarden-smtp_password
}

# combine all ports
locals {
    external_ports = concat([var.jupyter_port,var.coder_port, var.finance_port, var.bitwarden-port], split(",", var.coder_additional_ports))         
}

# expose nodeport to external network
resource "google_compute_firewall" "default" {  
    count       = local.node_count != 1 ? 0 : 1
    depends_on  = [google_container_node_pool.nodes]
    name        = "nodeport-firewall-${formatdate("YYYYMMDDhhss", timestamp())}"
    network     = google_container_cluster.primary.network

    allow {
        protocol = "tcp"
        ports    = local.external_ports
    }
}

# deploy dns assigner
module "libcloud-dynamic-dns" {
    source                  = "github.com/gumlooter/libcloud-dynamic-dns"
    module_count            = local.node_count # 0 to turn it off
    node_pool               = google_container_node_pool.nodes
    persistent_disk         = var.ddns-config-disk
    service_account_name    = var.ddns-service-account-name
    service_account_json    = var.ddns-service-account-json
    subdomain               = var.dns-subdomain
    zone                    = "${var.dns-zone}."
    project_name            = var.project_id
}
