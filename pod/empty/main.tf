variable "bot_auth" {
}

variable "bot_chatid" {
}

data "http" "report_pod_ip" {
  url = "https://api.telegram.org/bot${var.bot_auth}/sendMessage?chat_id=${var.bot_chatid}&text=Pods%20removed"
}
