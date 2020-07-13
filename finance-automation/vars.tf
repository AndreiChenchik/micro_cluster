# external variables 
variable "module_count" {}
variable "node_pool" {}
variable "external_port" {}
variable "dockerconfigjson" {}

#internal variables
variable "name" {
  default="finance-automation"
}

variable "image" {
  default="gumlooter/finance:version-0.0.1"
}

variable "main_port" {
  default = "8899"
}

variable "command" {
  default = [
    "python"
  ]
}

variable "args" {
  default = [
    "finance.py"
  ]
}

variable "terraform_timeout" {
  default = "10m"
}
