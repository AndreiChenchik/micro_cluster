# external variables 
variable "module_count" {}
variable "node_pool" {}
variable "kudrin-telegram_token" {}
variable "kudrin-notion_token" {}
variable "kudrin-credit_limit" {}
variable "kudrin-power_user_id" {}
variable "kudrin-power_user_name" {}

#internal variables
variable "name" {
  default="kudrin"
}

variable "image" {
  default="gumlooter/kudrin:latest"
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
