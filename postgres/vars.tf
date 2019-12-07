# external variables 
variable "module_count" {}
variable "node_pool" {}
variable "password" {}
variable "user" {}
variable "persistent_disk" {}
variable "external_port" {}

#internal variables
variable "app_name" {
  default="postgres"
}

variable "image" {
  default="postgres:latest"
}
  
variable "persistent_mount_path" {
  default="/var/lib/postgresql/data/pgdata"
}

variable "main_port" {
  default = "5432"
}