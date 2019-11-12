variable "app_name" {
  default="cloud-jupyter"
  }
  
variable "persistent-disk-name" {
  }
  
variable "docker_image" {
  default="jupyter/base-notebook:latest"
  }
  
variable "mount_path" {
  default="/home/jovyan/work"
  }

variable "envs" {
  default = [
    {
      name="JUPYTER_ENABLE_LAB"
      value="yes"
      },
    ]
  }

variable "command" {
  default="start-notebook.sh"
  }

variable "args" {
  default = [
    "--notebook-dir=/home/jovyan/work/lab",
    "--NotebookApp.ip=0.0.0.0",
    "--NotebookApp.allow_origin='*'",
    "--NotebookApp.token=''"
    ]
  }

variable "jupyter_password" {
}

variable "container_port" {
  default = 8888
  }

variable "external_port" {
  default = 80
  }
