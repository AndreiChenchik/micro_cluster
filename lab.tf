variable "credentials" {
}

variable "bot_auth" {
}

variable "bot_chatid" {
}

data "http" "report_terraforming" {
  	url = "https://api.telegram.org/bot${var.bot_auth}/sendMessage?chat_id=${var.bot_chatid}&text=Terraforming%20Started"
}

provider "google" {
 credentials = var.credentials
 project     = "chenchik-family-project"
 region      = "us-east1"
 zone        = "us-east1-c"
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "g1-small"
  #machine_type = "f1-micro"
  allow_stopping_for_update = true
 
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network       = "default"
    access_config {
    }
  }
}


data "http" "report_instance_ip" {
		depends_on = [google_compute_instance.vm_instance]
  	url = "https://api.telegram.org/bot${var.bot_auth}/sendMessage?chat_id=${var.bot_chatid}&text=Instance%20IP%20${google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip}"
}





