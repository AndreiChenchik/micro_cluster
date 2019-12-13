# external variables 
variable "module_count" {}
variable "node_pool" {}
variable "password" {}
variable "user" {}
variable "persistent_disk" {}

#internal variables
variable "name" {
  default="postgres"
}

variable "image" {
  default="postgres:latest"
}
  
variable "persistent_mount_path" {
  default="/var/lib/postgresql/data"
}

variable "main_port" {
  default = "5432"
}
