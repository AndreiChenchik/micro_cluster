# calculate local vars based on input vars
locals {
    # decide to run or not to run based on count input
    onoff_switch = var.module_count != 1 ? 0 : 1
}

# prepare env variables
resource "kubernetes_config_map" "global_override_env" {
    metadata {
        name = "global.override.env"
    }

    data = {
        globalSettings__baseServiceUri__vault               = "https://${var.bitwarden-host}:${var.bitwarden-port}"
        globalSettings__baseServiceUri__api                 = "https://${var.bitwarden-host}:${var.bitwarden-port}/api"
        globalSettings__baseServiceUri__identity            = "https://${var.bitwarden-host}:${var.bitwarden-port}/identity"
        globalSettings__baseServiceUri__admin               = "https://${var.bitwarden-host}:${var.bitwarden-port}/admin"
        globalSettings__baseServiceUri__notifications       = "https://${var.bitwarden-host}:${var.bitwarden-port}/notifications"
        globalSettings__sqlServer__connectionString         = "Data Source=tcp:mssql,1433;Initial Catalog=vault;Persist Security Info=False;User ID=sa;Password=${var.bitwarden-mssql_password};MultipleActiveResultSets=False;Connect Timeout=30;Encrypt=True;TrustServerCertificate=True"
        globalSettings__identityServer__certificatePassword = var.bitwarden-identity_cert_password
        globalSettings__attachment__baseDirectory           = "/etc/bitwarden/core/attachments"
        globalSettings__attachment__baseUrl                 = "https://${var.bitwarden-host}:${var.bitwarden-port}/attachments"
        globalSettings__dataProtection__directory           = "/etc/bitwarden/core/aspnet-dataprotection"
        globalSettings__logDirectory                        = "/etc/bitwarden/logs"
        globalSettings__licenseDirectory                    = "/etc/bitwarden/core/licenses"
        globalSettings__internalIdentityKey                 = var.bitwarden-identity_key
        globalSettings__duo__aKey                           = var.bitwarden-duo_key
        globalSettings__installation__id                    = var.bitwarden-installation_id
        globalSettings__installation__key                   = var.bitwarden-installation_key
        globalSettings__yubico__clientId                    = "REPLACE"
        globalSettings__yubico__key                         = "REPLACE"
        globalSettings__mail__replyToEmail                  = var.bitwarden-reply_to
        globalSettings__mail__smtp__host                    = "REPLACE"
        globalSettings__mail__smtp__port                    = "587"
        globalSettings__mail__smtp__ssl                     = "false"
        globalSettings__mail__smtp__username                = "REPLACE"
        globalSettings__mail__smtp__password                = "REPLACE"
        globalSettings__disableUserRegistration             = "false"
        globalSettings__hibpApiKey                          = "REPLACE"
        adminSettings__admins                               = ""
    }
}


resource "kubernetes_config_map" "mssql_override_env" {
    metadata {
        name = "mssql.override.env"
    }

    data = {
        ACCEPT_EULA = "Y"
        MSSQL_PID   = "Express"
        SA_PASSWORD = var.bitwarden-mssql_password
    }
}


resource "kubernetes_config_map" "uid_env" {
    metadata {
        name = "uid.env"
    }

    data = {
        LOCAL_UID   = 0
        LOCAL_GID   = 0
    }
}


resource "kubernetes_config_map" "global_env" {
    metadata {
        name = "global.env"
    }

    data = {
        ASPNETCORE_ENVIRONMENT                                  = "Production"
        globalSettings__selfHosted                              = "true"
        globalSettings__baseServiceUri__vault                   = "http://localhost"
        globalSettings__baseServiceUri__api                     = "http://localhost/api"
        globalSettings__baseServiceUri__identity                = "http://localhost/identity"
        globalSettings__baseServiceUri__admin                   = "http://localhost/admin"
        globalSettings__baseServiceUri__notifications           = "http://localhost/notifications"
        globalSettings__baseServiceUri__internalNotifications   = "http://notifications:5000"
        globalSettings__baseServiceUri__internalAdmin           = "http://admin:5000"
        globalSettings__baseServiceUri__internalIdentity        = "http://identity:5000"
        globalSettings__baseServiceUri__internalApi             = "http://api:5000"
        globalSettings__baseServiceUri__internalVault           = "http://web:5000"
        globalSettings__pushRelayBaseUri                        = "https://push.bitwarden.com"
        globalSettings__installation__identityUri               = "https://identity.bitwarden.com"
    }
}


resource "kubernetes_config_map" "mssql_env" {
    metadata {
        name = "mssql.env"
    }

    data = {
        ACCEPT_EULA = "Y"
        MSSQL_PID   = "Express"
        SA_PASSWORD = var.bitwarden-mssql_password
    }
}


# schedule pod with container
resource "kubernetes_deployment" "mssql" {
    # create resource only if there it's required
    count = local.onoff_switch

    metadata {
        name = "bitwarden-mssql"
    }
    
    # wait for gke node pool
    depends_on = [var.node_pool]

    spec {
        # we need only one replica of the service
        replicas = 1
        
        selector {
            match_labels = {
                app = "bitwarden-mssql"
            }
        }
        
        # pod configuration
        template {
            metadata {
                labels = {
                    app = "bitwarden-mssql"
                }
            }

            spec {
                container {
                    name    = "bitwarden-mssql"
                    image   = "bitwarden/mssql:latest"  
                    
                    # envs
                    env_from {
                        config_map_ref {
                            name = "mssql.env"
                        }
                    }

                    env_from {
                        config_map_ref {
                            name = "uid.env"
                        }
                    }

                    env_from {
                        config_map_ref {
                            name = "mssql.override.env"
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

# schedule pod with container
resource "kubernetes_deployment" "web" {
    # create resource only if there it's required
    count = local.onoff_switch

    metadata {
        name = "bitwarden-web"
    }
    
    # wait for gke node pool
    depends_on = [var.node_pool]

    spec {
        # we need only one replica of the service
        replicas = 1
        
        selector {
            match_labels = {
                app = "bitwarden-web"
            }
        }
        
        # pod configuration
        template {
            metadata {
                labels = {
                    app = "bitwarden-web"
                }
            }

            spec {
                # attach identity
                volume {
                    name= "app-id"
                    config_map {
                        name = "app-id"
                    }
                }


                container {
                    name    = "bitwarden-web"
                    image   = "bitwarden/web:latest"  
                    
                    # envs
                    env_from {
                        config_map_ref {
                            name = "global.env"
                        }
                    }
                    
                    env_from {
                        config_map_ref {
                            name = "uid.env"
                        }
                    }

                    # mount app-id
                    volume_mount {
                        mount_path = "/etc/bitwarden/web"
                        name = "app-id"
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

# schedule pod with container
resource "kubernetes_deployment" "attachments" {
    # create resource only if there it's required
    count = local.onoff_switch

    metadata {
        name = "bitwarden-attachments"
    }
    
    # wait for gke node pool
    depends_on = [var.node_pool]

    spec {
        # we need only one replica of the service
        replicas = 1
        
        selector {
            match_labels = {
                app = "bitwarden-attachments"
            }
        }
        
        # pod configuration
        template {
            metadata {
                labels = {
                    app = "bitwarden-attachments"
                }
            }

            spec {
                container {
                    name    = "bitwarden-attachments"
                    image   = "bitwarden/attachments:latest"  
                    
                    # envs
                    env_from {
                        config_map_ref {
                            name = "global.env"
                        }
                    }
                    
                    env_from {
                        config_map_ref {
                            name = "uid.env"
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

# schedule pod with container
resource "kubernetes_deployment" "api" {
    # create resource only if there it's required
    count = local.onoff_switch

    metadata {
        name = "bitwarden-api"
    }
    
    # wait for gke node pool
    depends_on = [var.node_pool]

    spec {
        # we need only one replica of the service
        replicas = 1
        
        selector {
            match_labels = {
                app = "bitwarden-api"
            }
        }
        
        # pod configuration
        template {
            metadata {
                labels = {
                    app = "bitwarden-api"
                }
            }

            spec {
                container {
                    name    = "bitwarden-api"
                    image   = "bitwarden/api:latest"  
                    
                    # envs
                    env_from {
                        config_map_ref {
                            name = "global.env"
                        }
                    }
                    
                    env_from {
                        config_map_ref {
                            name = "uid.env"
                        }
                    }

                    env_from {
                        config_map_ref {
                            name = "global.override.env"
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

# schedule pod with container
resource "kubernetes_deployment" "identity" {
    # create resource only if there it's required
    count = local.onoff_switch

    metadata {
        name = "bitwarden-identity"
    }
    
    # wait for gke node pool
    depends_on = [var.node_pool]

    spec {
        # we need only one replica of the service
        replicas = 1
        
        selector {
            match_labels = {
                app = "bitwarden-identity"
            }
        }
        
        # pod configuration
        template {
            metadata {
                labels = {
                    app = "bitwarden-identity"
                }
            }

            spec {
                # attach identity
                volume {
                    name= "identity"
                    config_map {
                        name = "identity"
                    }
                }

                container {
                    name    = "bitwarden-identity"
                    image   = "bitwarden/identity:latest"  
                    
                    # envs
                    env_from {
                        config_map_ref {
                            name = "global.env"
                        }
                    }
                    
                    env_from {
                        config_map_ref {
                            name = "uid.env"
                        }
                    }

                    env_from {
                        config_map_ref {
                            name = "global.override.env"
                        }
                    }

                    # mount identity
                    volume_mount {
                        mount_path = "/etc/bitwarden/identity"
                        name = "identity"
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

# schedule pod with container
resource "kubernetes_deployment" "icons" {
    # create resource only if there it's required
    count = local.onoff_switch

    metadata {
        name = "bitwarden-icons"
    }
    
    # wait for gke node pool
    depends_on = [var.node_pool]

    spec {
        # we need only one replica of the service
        replicas = 1
        
        selector {
            match_labels = {
                app = "bitwarden-icons"
            }
        }
        
        # pod configuration
        template {
            metadata {
                labels = {
                    app = "bitwarden-icons"
                }
            }

            spec {
                container {
                    name    = "bitwarden-icons"
                    image   = "bitwarden/icons:latest"  
                    
                    # envs
                    env_from {
                        config_map_ref {
                            name = "global.env"
                        }
                    }
                    
                    env_from {
                        config_map_ref {
                            name = "uid.env"
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

# schedule pod with container
resource "kubernetes_deployment" "notifications" {
    # create resource only if there it's required
    count = local.onoff_switch

    metadata {
        name = "bitwarden-notifications"
    }
    
    # wait for gke node pool
    depends_on = [var.node_pool]

    spec {
        # we need only one replica of the service
        replicas = 1
        
        selector {
            match_labels = {
                app = "bitwarden-notifications"
            }
        }
        
        # pod configuration
        template {
            metadata {
                labels = {
                    app = "bitwarden-notifications"
                }
            }

            spec {
                container {
                    name    = "bitwarden-notifications"
                    image   = "bitwarden/notifications:latest"  
                    
                    # envs
                    env_from {
                        config_map_ref {
                            name = "global.env"
                        }
                    }
                    
                    env_from {
                        config_map_ref {
                            name = "uid.env"
                        }
                    }

                    env_from {
                        config_map_ref {
                            name = "global.override.env"
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

# schedule pod with container
resource "kubernetes_deployment" "events" {
    # create resource only if there it's required
    count = local.onoff_switch

    metadata {
        name = "bitwarden-events"
    }
    
    # wait for gke node pool
    depends_on = [var.node_pool]

    spec {
        # we need only one replica of the service
        replicas = 1
        
        selector {
            match_labels = {
                app = "bitwarden-events"
            }
        }
        
        # pod configuration
        template {
            metadata {
                labels = {
                    app = "bitwarden-events"
                }
            }

            spec {
                container {
                    name    = "bitwarden-events"
                    image   = "bitwarden/events:latest"  
                    
                    # envs
                    env_from {
                        config_map_ref {
                            name = "global.env"
                        }
                    }
                    
                    env_from {
                        config_map_ref {
                            name = "uid.env"
                        }
                    }

                    env_from {
                        config_map_ref {
                            name = "global.override.env"
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

# schedule pod with container
resource "kubernetes_deployment" "nginx" {
    # create resource only if there it's required
    count = local.onoff_switch

    metadata {
        name = "bitwarden-nginx"
    }
    
    # wait for gke node pool
    depends_on = [var.node_pool, kubernetes_service.web, kubernetes_service.api, kubernetes_service.identity, kubernetes_service.admin, kubernetes_config_map.nginx_config, kubernetes_config_map.nginx_certs]

    spec {
        # we need only one replica of the service
        replicas = 1
        
        selector {
            match_labels = {
                app = "bitwarden-nginx"
            }
        }
        
        # pod configuration
        template {
            metadata {
                labels = {
                    app = "bitwarden-nginx"
                }
            }

            spec {
                 # attach certs
                volume {
                    name= "bitwarden-nginx-certs"

                    config_map {
                        default_mode = "0777"
                        name = "bitwarden-nginx-certs"
                    }
                }
                
                # attach config
                volume {
                    name= "bitwarden-nginx-config"
                    
                    config_map {
                        default_mode = "0777"
                        name = "bitwarden-nginx-config"
                    }
                }

                container {
                    name    = "bitwarden-nginx"
                    image   = "bitwarden/nginx:latest"  
                    
                    # envs
                    env_from {
                        config_map_ref {
                            name = "uid.env"
                        }
                    }
                    
                    # mount config
                    volume_mount {
                        mount_path = "/etc/bitwarden/nginx"
                        name = "bitwarden-nginx-config"
                    }

                    # mount certs
                    volume_mount {
                        mount_path = "/etc/ssl/${var.bitwarden-host}"
                        name = "bitwarden-nginx-certs"
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

# schedule pod with container
resource "kubernetes_deployment" "admin" {
    # create resource only if there it's required
    count = local.onoff_switch

    metadata {
        name = "bitwarden-admin"
    }
    
    # wait for gke node pool
    depends_on = [var.node_pool, kubernetes_deployment.mssql]

    spec {
        # we need only one replica of the service
        replicas = 1
        
        selector {
            match_labels = {
                app = "bitwarden-admin"
            }
        }
        
        # pod configuration
        template {
            metadata {
                labels = {
                    app = "bitwarden-admin"
                }
            }

            spec {
                container {
                    name    = "bitwarden-admin"
                    image   = "bitwarden/admin:latest"  
                    
                    # envs
                    env_from {
                        config_map_ref {
                            name = "global.env"
                        }
                    }
                    
                    env_from {
                        config_map_ref {
                            name = "uid.env"
                        }
                    }

                    env_from {
                        config_map_ref {
                            name = "global.override.env"
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


# define certs
resource "kubernetes_config_map" "nginx_certs" {
    metadata {
        name = "bitwarden-nginx-certs"
    }

    data = {
        "private.key"       = var.bitwarden-cert_key
        "certificate.crt"   = var.bitwarden-cert
        "ca.crt"            = var.bitwarden-cert_ca
    }
}

# define config
resource "kubernetes_config_map" "nginx_config" {
    metadata {
        name = "bitwarden-nginx-config"
    }

    data = {
        "default.conf" = templatefile("${path.module}/nginx.tmpl", { host = var.bitwarden-host, port = var.bitwarden-port })
    }
}

# define app-id
resource "kubernetes_config_map" "app-id" {
    metadata {
        name = "app-id"
    }

    data = {
        "app-id.json" = templatefile("${path.module}/app-id.tmpl", { host = var.bitwarden-host, port = var.bitwarden-port })
    }
}

# define identity
resource "kubernetes_config_map" "identity" {
    metadata {
        name = "identity"
    }
    binary_data = {
        "identity.pfx" = "${filebase64("${path.module}/identity.bin")}"
    }
}


# add nodeport to drive external traffic to pod
resource "kubernetes_service" "external" {
    # create resource only if there it's required
    count = local.onoff_switch

    metadata {
        name = "bitwarden-nginx"
    }

    # wait for deployment
    depends_on = [kubernetes_deployment.nginx]
    
    spec {
        selector = {
            # choose only our app
            app = "bitwarden-nginx"
        }
        
        port {
            # expose main port of our container
            name = "main-port"
            port = 8443
            node_port = var.bitwarden-port
        } 

        type = "NodePort"
    }
}


resource "kubernetes_service" "web" {
    count = local.onoff_switch

    metadata {
        name = "bitwarden-web"
    }

    depends_on = [kubernetes_deployment.web]
    
    spec {
        selector = {
            app = "bitwarden-web"
        }
        
        port {
            # expose main port of our container
            name = "web-port"
            port = 5000
        } 
    }
}

resource "kubernetes_service" "icons" {
    count = local.onoff_switch

    metadata {
        name = "bitwarden-icons"
    }

    depends_on = [kubernetes_deployment.icons]
    
    spec {
        selector = {
            app = "bitwarden-icons"
        }
        
        port {
            # expose main port of our container
            name = "icons-port"
            port = 5000
        } 
    }
}

resource "kubernetes_service" "notifications" {
    count = local.onoff_switch

    metadata {
        name = "bitwarden-notifications"
    }

    depends_on = [kubernetes_deployment.notifications]
    
    spec {
        selector = {
            app = "bitwarden-notifications"
        }
        
        port {
            # expose main port of our container
            name = "notifications-port"
            port = 5000
        } 
    }
}

resource "kubernetes_service" "events" {
    count = local.onoff_switch

    metadata {
        name = "bitwarden-events"
    }

    depends_on = [kubernetes_deployment.events]
    
    spec {
        selector = {
            app = "bitwarden-events"
        }
        
        port {
            # expose main port of our container
            name = "events-port"
            port = 5000
        } 
    }
}

resource "kubernetes_service" "admin" {
    count = local.onoff_switch

    metadata {
        name = "bitwarden-admin"
    }

    depends_on = [kubernetes_deployment.admin]
    
    spec {
        selector = {
            app = "bitwarden-admin"
        }
        
        port {
            # expose main port of our container
            name = "admin-port"
            port = 5000
        } 
    }
}

resource "kubernetes_service" "attachments" {
    count = local.onoff_switch

    metadata {
        name = "bitwarden-attachments"
    }

    depends_on = [kubernetes_deployment.attachments]
    
    spec {
        selector = {
            app = "bitwarden-attachments"
        }
        
        port {
            # expose main port of our container
            name = "attachments-port"
            port = 5000
        } 
    }
}


resource "kubernetes_service" "identity" {
    count = local.onoff_switch

    metadata {
        name = "bitwarden-identity"
    }

    depends_on = [kubernetes_deployment.identity]
    
    spec {
        selector = {
            app = "bitwarden-identity"
        }
        
        port {
            # expose main port of our container
            name = "identity-port"
            port = 5000
        } 
    }
}

resource "kubernetes_service" "api" {
    count = local.onoff_switch

    metadata {
        name = "bitwarden-api"
    }

    depends_on = [kubernetes_deployment.api]
    
    spec {
        selector = {
            app = "bitwarden-api"
        }
        
        port {
            # expose main port of our container
            name = "api-port"
            port = 5000
        } 
    }
}