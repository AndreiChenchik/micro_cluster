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
variable "postgres_password" {}
variable "postgres_port" {}
variable "postgres_disk" {}
variable "persistent-disk-name" {}
variable "ddns-config-disk" {}
variable "ddns-service-account-name" {}
variable "ddns-service-account-json" {}
variable "coder_port" {}
variable "coder_password" {}
variable "coder_disk" {}
variable "coder_additional_ports" {}
variable "dockerconfigjson" {}
variable "finance_port" {}
variable "telegram_token" {}
variable "notion_token" {}
variable "credit_limit" {}

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

