# Jupyter Notebook
resource "kubernetes_deployment" "jupyter_deployment" {
  # create resource only if there is any nodes
  count = var.onoff_switch
  
  # wait for gke node pool
  depends_on = var.dependency_list

  spec {
    replicas = 1
    template {
      metadata {
        labels = {
          app = var.command
        }
      }

      spec {
        container {
          image = var.image
          command = [var.command]
          args = local.args      
          
          # all the jupyter settings
          env {
            name = var.envs[0].name
            value = var.envs[0].value
          }     
          
          # expose ports
          port {
            container_port = var.main_port
          }

          # attach persistent-disk to node
          volume {
            name= "persistent-volume"
            gce_persistent_disk {
              pd_name = var.persistent_disk
            }
          }

          # mount disk to container
          volume_mount {
            mount_path = var.persistent_mount_path
            name = "persistent-volume"
          }      
        }
        
        # terraform: give container more time to load image (it's huge)
        timeouts {
          create = var.terraform_timeout
        }
      }      
    }
  }
}
