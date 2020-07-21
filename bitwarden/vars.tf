# external variables 
variable "module_count" {}
variable "node_pool" {}
variable "bitwarden-installation_id" {}
variable "bitwarden-installation_key" {}
variable "bitwarden-host" {}
variable "bitwarden-port" {}
variable "bitwarden-identity_cert_password" {}
variable "bitwarden-mssql_password" {}
variable "bitwarden-identity_key" {}
variable "bitwarden-duo_key" {}
variable "bitwarden-reply_to" {}
variable "bitwarden-cert_key" {}
variable "bitwarden-cert" {}
variable "bitwarden-cert_ca" {}
variable "bitwarden-smtp_host" {}
variable "bitwarden-smtp_port" {}
variable "bitwarden-smtp_ssl" {}
variable "bitwarden-smtp_username" {}
variable "bitwarden-smtp_password" {}
variable "bitwarden-identity_pfx" {}

#internal variables
variable "name" {
    default = "bitwarden"
}

variable "terraform_timeout" {
    default = "10m"
}

