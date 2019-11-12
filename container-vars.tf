variable "app_name" {
  default="cloud-jupyter"
  }
  
variable "persistent-disk-name" {
  }
  
variable "docker_image" {
  default="docker.pkg.github.com/gumlooter/lab/jupyter:20191023162926d64653"
  }
  
variable "mount_path" {
  default="/home/jovyan/work"
  }
  
variable "exposed_port" {
  default="8888"
  }
