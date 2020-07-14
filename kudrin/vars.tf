# external variables 
variable "module_count" {}
variable "node_pool" {}
variable "telegram_token" {}
variable "notion_token" {}
variable "credit_limit" {}

#internal variables
variable "name" {
  default="kudrin"
}

variable "image" {
  default="gumlooter/kudrin:version-0.0.3"
}

variable "command" {
  default = [
    "python"
  ]
}

variable "args" {
  default = [
    "main.py"
  ]
}

variable "terraform_timeout" {
  default = "10m"
}
