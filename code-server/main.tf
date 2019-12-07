# HOW TO USE:
# add following to your terraform config
#module "code-server" {
#  source = "./code-server"
#  module_count = 1 # 0 to turn it off
#  node_pool = google_container_node_pool.nodes
#  persistent_disk = "storage-disk"
#  external_port = 30004
#  password = "mysecretpassword"
#  additional_ports = "30011,30012,30013,30014,30015"
#}

# calculate local vars based on input vars
locals {
  # decide to run or not to run based on count input
  onoff_switch = var.module_count != 1 ? 0 : 1
  # extract additional ports info
  additional_ports = split(",", var.additional_ports)
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
          
          # password settings
          env {
            name = "PASSWORD"
            value = var.password
          }    
          
          # expose ports          
          port {
            # expose main port of our container
            name = "main-port"
            container_port = var.main_port
          } 

          port {
            name = "10-port"
            container_port = 8010
          }

          port {
            name = "11-port"
            container_port = 8011
          }

          port {
            name = "12-port"
            container_port = 8012
          }

          port {
            name = "13-port"
            container_port = 8013
          }

          port {
            name = "14-port"
            container_port = 8014
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
  
  # terraform: give container more time to load image (it's huge)
  timeouts {
    create = var.terraform_timeout
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
    
    port {
      name = "10-port"
      port = 8010
      node_port = local.additional_ports[0]
    }
    
    port {
      name = "11-port"
      port = 8011
      node_port = local.additional_ports[1]
    }
    
    port {
      name = "12-port"
      port = 8012
      node_port = local.additional_ports[2]
    }
    
    port {
      name = "13-port"
      port = 8013
      node_port = local.additional_ports[3]
    }
    
    port {
      name = "14-port"
      port = 8014
      node_port = local.additional_ports[4]
    }
    
    type = "NodePort"
  }
}
