variable "credentials" {
}

variable "bot_auth" {
}

variable "bot_chatid" {
}

variable "project_id" {
}

variable "region" {
  default = "us-east1"
}

variable "zone" {
  default = "us-east1-c"
}

variable "node_type" {
  default = "g1-small"
  #default = "othertype"
}

variable "node_count" {
  default = 1
  #default = 0
}
