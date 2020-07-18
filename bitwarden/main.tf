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
        globalSettings__baseServiceUri__vault               = "https://{$var.bitwarden-host}:{$var.bitwarden-port}"
        globalSettings__baseServiceUri__api                 = "https://{$var.bitwarden-host}:{$var.bitwarden-port}/api"
        globalSettings__baseServiceUri__identity            = "https://{$var.bitwarden-host}:{$var.bitwarden-port}/identity"
        globalSettings__baseServiceUri__admin               = "https://{$var.bitwarden-host}:{$var.bitwarden-port}/admin"
        globalSettings__baseServiceUri__notifications       = "https://{$var.bitwarden-host}:{$var.bitwarden-port}/notifications"
        globalSettings__sqlServer__connectionString         = "Data Source=tcp:mssql,1433;Initial Catalog=vault;Persist Security Info=False;User ID=sa;Password={$var.bitwarden-mssql_password};MultipleActiveResultSets=False;Connect Timeout=30;Encrypt=True;TrustServerCertificate=True"
        globalSettings__identityServer__certificatePassword = var.bitwarden-identity_cert_password
        globalSettings__attachment__baseDirectory           = "/etc/bitwarden/core/attachments"
        globalSettings__attachment__baseUrl                 = "https://{$var.bitwarden-host}:{$var.bitwarden-port}/attachments"
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
                 # attach certs
                volume {
                    name= "certs"
                    config_map {
                        name = "tls-certs"
                    }
                }
                
                # attach config
                volume {
                    name= "config"
                    config_map {
                        name = "nginx"
                    }
                }

                # attach identity
                volume {
                    name= "identity"
                    config_map {
                        name = "identity"
                    }
                }

                # attach identity
                volume {
                    name= "app-id"
                    config_map {
                        name = "app-id"
                    }
                }

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
                        name = "config"
                    }

                    # mount certs
                    volume_mount {
                        mount_path = "/etc/ssl/{$var.bitwarden-host}"
                        name = "certs"
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
resource "kubernetes_config_map" "tls-certs" {
    metadata {
        name = "tls-certs"
    }

    data = {
        "private.key"       = var.bitwarden-cert_key
        "certificate.crt"   = var.bitwarden-cert
        "ca.crt"            = var.bitwarden-cert_ca
    }
}

# define config
resource "kubernetes_config_map" "nginx" {
    metadata {
        name = "nginx"
    }

    data = {
        "default.config" = templatefile("${path.module}/nginx.tmpl", { host = var.bitwarden-host, port = var.bitwarden-port })
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
            port = 8443
            node_port = var.bitwarden-port
        } 

        type = "NodePort"
    }
}