# external variables 
variable "module_count" {}
variable "node_pool" {}
variable "password" {}
variable "persistent_disk" {}
variable "external_port" {}
variable "additional_ports" {}

#internal variables
variable "app_name" {
  default="code-server"
}

variable "container_name" {
  default="code-server-container"
}

variable "deployment_name" {
  default="code-server-deployment"
}

variable "image" {
  default="codercom/code-server:v2"
}
  
variable "persistent_mount_path" {
  default="/home"
}

variable "main_port" {
  default = "8889"
}

variable "command" {
  default = [
    "code-server"
  ]
}

variable "args" {
  default = [
    "--cert"
  ]
}

variable "terraform_timeout" {
  default = "10m"
}
