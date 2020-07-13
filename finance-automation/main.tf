# calculate local vars based on input vars
locals {
  # decide to run or not to run based on count input
  onoff_switch = var.module_count != 1 ? 0 : 1
}

resource "kubernetes_secret" "docker_pull_secret" {
  metadata {
    name = "docker-cfg"
  }

  data = {
    ".dockerconfigjson" = "${var.dockerconfigjson}"
  }

  type = "kubernetes.io/dockerconfigjson"
}

# schedule pod with container
resource "kubernetes_deployment" "main" {
  # create resource only if there it's required
  count = local.onoff_switch

  metadata {
    name = var.name
  }
  
  # wait for gke node pool
  depends_on = [var.node_pool]

  spec {
    # we need only one replica of the service
    replicas = 1
    
    selector {
      match_labels = {
        app = var.name
      }
    }
    
    # pod configuration
    template {
      metadata {
        labels = {
          app = var.name
        }
      }

      spec {
        image_pull_secrets {
          name = "${kubernetes_secret.docker_pull_secret.metadata.0.name}"
        }
        container {
          name = var.name
          command = var.command
          args = var.args
          image = var.image      
          
          # expose ports          
          port {
            # expose main port of our container
            name = "main-port"
            container_port = var.main_port
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
resource "kubernetes_service" "main" {
  # create resource only if there it's required
  count = local.onoff_switch

  metadata {
    name = var.name
  }

  # wait for deployment
  depends_on = [kubernetes_deployment.main]
  
  spec {
    selector = {
      # choose only our app
      app = var.name
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
