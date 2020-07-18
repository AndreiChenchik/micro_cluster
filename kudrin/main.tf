# calculate local vars based on input vars
locals {
    # decide to run or not to run based on count input
    onoff_switch = var.module_count != 1 ? 0 : 1
}

# prepare env variables
resource "kubernetes_config_map" "envs" {
    metadata {
        name = var.name
    }

    data = {
        TELEGRAM_TOKEN  = var.kudrin-telegram_token
        POWER_USER_NAME = var.kudrin-power_user_name
        POWER_USER_ID   = var.kudrin-power_user_id           
        NOTION_TOKEN    = var.kudrin-notion_token
        CREDIT_LIMIT    = var.kudrin-credit_limit
    }
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
                container {
                    name = var.name
                    command = var.command
                    args = var.args
                    image = var.image  
                    
                    # envs
                    env_from {
                        config_map_ref {
                            name = var.name
                        }
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
