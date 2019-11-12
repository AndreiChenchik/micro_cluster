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

variable "envs" {
  default {
    name="JUPYTER_ENABLE_LAB"
    value="yes"
    }
  }

variable "command" {
  defaul="start-notebook.sh"
  }

variable "args" {
  default = [
    "--notebook-dir=/home/jovyan/work",
    "--NotebookApp.ip=0.0.0.0",
    "--NotebookApp.password_required=False",
    "--NotebookApp.token=''",
    "--NotebookApp.custom_display_url="{var.dns-subdomain}.${var.dns-zone}""
    ]
  }

variable "container_port" {
  default = 8888
  }
