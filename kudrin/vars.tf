# external variables 
variable "module_count" {}
variable "node_pool" {}
variable "telegram_token" {}
variable "notion_token" {}
variable "credit_limit" {}
variable "kudrin_power_user_id" {}
variable "kudrin_power_user_name" {}

#internal variables
variable "name" {
  default="kudrin"
}

variable "image" {
  default="gumlooter/kudrin:version-0.0.4"
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
