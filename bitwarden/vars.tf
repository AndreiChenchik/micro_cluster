# external variables 
variable "module_count" {}
variable "node_pool" {}

#internal variables
variable "name" {
    default = "bitwarden"
}

variable "terraform_timeout" {
    default = "10m"
}

