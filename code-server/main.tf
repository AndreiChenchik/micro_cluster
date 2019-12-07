# HOW TO USE:
# add following to your terraform config
#module "code-server" {
#  source = "./code-server"
#  module_count = 1 # 0 to turn it off
#  node_pool = google_container_node_pool.nodes
#  persistent_disk = "storage-disk"
#  external_port = 30004
#  password = "mysecretpassword"
#}

# calculate local vars based on input vars
locals {
  # decide to run or not to run based on count input
  onoff_switch = var.module_count != 1 ? 0 : 1
}

# schedule service
resource "kubernetes_deployment" "main" {
  # create resource only if there it's required
  count = local.onoff_switch

  metadata {
    name = var.deployment_name
  }
  
  # wait for gke node pool
  depends_on = [var.node_pool]

  spec {
    # we need only one replica of the service
    replicas = 1
    
    selector {
      match_labels = {
        app = var.app_name
      }
    }
    
    # pod configuration
    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }

      spec {
        # attach persistent-disk to node
        volume {
          name= "persistent-volume"
          gce_persistent_disk {
            pd_name = var.persistent_disk
          }
        }  
        
        container {
          name = var.container_name
          command = var.command
          args = var.args
          image = var.image    
          

          
          # expose ports
          port {
            container_port = var.main_port
          }

          # mount disk to container
          volume_mount {
            mount_path = var.persistent_mount_path
            name = "persistent-volume"
          }      
        }
      }      
    }
  }
}

# add nodeport to drive external traffic to pod
resource "kubernetes_service" "node_port" {
  # create resource only if there it's required
  count = local.onoff_switch

  metadata {
    name = "code-server-nodeport"
  }

  # wait for deployment
  depends_on = [kubernetes_deployment.main]
  
  spec {
    selector = {
      # choose only our app
      app = var.app_name
    }
    
    port {
      # expose main port of our container
      name = "main-port"
      port = var.main_port
      node_port = var.external_port
    }    
  
    type = "NodePort"
  }
}
