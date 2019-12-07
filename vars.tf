variable "credentials" {}
variable "bot_auth" {}
variable "bot_chatid" {}
variable "project_id" {}
variable "dns-zone-name" {}
variable "dns-zone" {}
variable "dns-subdomain" {}
variable "email" {}
variable "jupyter_password" {}
variable "jupyter_port" {}
variable "postgres_user" {}
variable "postgres_password" {}
variable "postgres_port" {}
variable "postgres_disk" {}
variable "persistent-disk-name" {}
variable "ddns-config-disk" {}

variable "cluster_name" {
  default = "default-cluster"
}

variable "pool_name" {
  default = "default-pool"
}

variable "region" {
  default = "europe-north1"
}

variable "zone" {
  default = "europe-north1-b"
}

