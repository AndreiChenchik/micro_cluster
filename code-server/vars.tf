# external variables 
variable "module_count" {}
variable "node_pool" {}
variable "password" {}
variable "persistent_disk" {}
variable "external_port" {}
variable "additional_ports" {}
variable "cert_key" {}
variable "cert" {}

#internal variables
variable "name" {
  default="code-server"
}

variable "image" {
  default="codercom/code-server:v2"
}
  
variable "persistent_mount_path" {
  default="/home"
}

variable "main_port" {
  default = "8080"
}

variable "command" {
  default = [
    "code-server"
  ]
}

variable "args" {
  default = [
    "--cert", "/etc/certs/cert",
    "--cert_key", "/etc/certs/cert_key"
  ]
}

variable "terraform_timeout" {
  default = "10m"
}
