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
        globalSettings__baseServiceUri__vault               = "https://bitwarden.example.com"
        globalSettings__baseServiceUri__api                 = "https://bitwarden.example.com/api"
        globalSettings__baseServiceUri__identity            = "https://bitwarden.example.com/identity"
        globalSettings__baseServiceUri__admin               = "https://bitwarden.example.com/admin"
        globalSettings__baseServiceUri__notifications       = "https://bitwarden.example.com/notifications"
        globalSettings__sqlServer__connectionString         = "Data Source=tcp:mssql,1433;Initial Catalog=vault;Persist Security Info=False;User ID=sa;Password=RANDOM_DATABASE_PASSWORD;MultipleActiveResultSets=False;Connect Timeout=30;Encrypt=True;TrustServerCertificate=True"
        globalSettings__identityServer__certificatePassword = "IDENTITY_CERT_PASSWORD"
        globalSettings__attachment__baseDirectory           = "/etc/bitwarden/core/attachments"
        globalSettings__attachment__baseUrl                 = "https://bitwarden.example.com/attachments"
        globalSettings__dataProtection__directory           = "/etc/bitwarden/core/aspnet-dataprotection"
        globalSettings__logDirectory                        = "/etc/bitwarden/logs"
        globalSettings__licenseDirectory                    = "/etc/bitwarden/core/licenses"
        globalSettings__internalIdentityKey                 = "RANDOM_IDENTITY_KEY"
        globalSettings__duo__aKey                           = "RANDOM_DUO_AKEY"
        globalSettings__installation__id                    = "00000000-0000-0000-0000-000000000000"
        globalSettings__installation__key                   = "SECRET_INSTALLATION_KEY"
        globalSettings__yubico__clientId                    = "REPLACE"
        globalSettings__yubico__key                         = "REPLACE"
        globalSettings__mail__replyToEmail                  = "no-reply@bitwarden.example.com"
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
        SA_PASSWORD = "RANDOM_DATABASE_PASSWORD"
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
        SA_PASSWORD = "SECRET"
    }
}


# schedule pod with container
resource "kubernetes_deployment" "main" {
    # create resource only if there it's required
    count = local.onoff_switch

    metadata {
        name = "bitwarden"
    }
    
    # wait for gke node pool
    depends_on = [var.node_pool]

    spec {
        # we need only one replica of the service
        replicas = 1
        
        selector {
            match_labels = {
                app = "bitwarden"
            }
        }
        
        # pod configuration
        template {
            metadata {
                labels = {
                    app = "bitwarden"
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
                }
            }      
        }
    }
    
    # terraform: give container more time to load image (it's huge)
    timeouts {
        create = var.terraform_timeout
    }
}