# HOW TO USE:
# add following to your terraform config
#module "postgres" {
#  source = "./postgres"
#  module_count = 1 # 0 to turn it off
#  node_pool = google_container_node_pool.nodes
#  persistent_disk = "db-storage"
#  user = "postgres"
#  password = "mysecretpassword"
#}

# calculate local vars based on input vars
locals {
  # decide to run or not to run based on count input
  onoff_switch = var.module_count != 1 ? 0 : 1
}

# schedule Jupyter Notebook
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
          image = var.image    
          
          # all the env settings
          # user
          env {
            name = "POSTGRES_USER"
            value = var.user
          }    
          
          # passsword
          env {
            name = "POSTGRES_PASSWORD"
            value = var.password
          }  
          
          # data folder
          env {
            name = "PGDATA"
            value = "${var.persistent_mount_path}/pgdata"
          }  
          
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

# add in-cluster connectivity to drive traffic to the pod
resource "kubernetes_service" "node_port" {
  # create resource only if there it's required
  count = local.onoff_switch

  metadata {
    name = "postgres-nodeport"
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
      target_port = var.main_port
    }    
  }
}
