module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "servicebus" {
  source  = "codectl/sb/azure"
  version = "~> 1.0"


  servicebus_namespace = {
    name                = module.naming.servicebus_namespace.name_unique
    resource_group_name = module.rg.groups.demo.name
    location            = module.rg.groups.demo.location

    queues = {
      orders = {
        default_message_ttl                  = "P14D"
        enable_partitioning                  = true
        dead_lettering_on_message_expiration = true
        max_delivery_count                   = 10
        enable_express                       = false
      }
    }

    topics = {
      notifications = {
        enable_partitioning   = true
        enable_express        = false
        max_size_in_megabytes = 5120

        subscriptions = {
          alerts = {
            max_delivery_count                   = 10
            dead_lettering_on_message_expiration = true
            enable_batched_operations            = true
          }
        }
      }
    }
  }
}

module "eventgrid" {
  source  = "codectl/eg/azure"
  version = "~> 1.0"

  eventgrid = {
    name                = module.naming.eventgrid_domain.name
    resource_group_name = module.rg.groups.demo.name
    location            = module.rg.groups.demo.location

    domains = {
      primary = {
        domain_topics = {
          orders = {
            event_subscriptions = local.event_subscriptions
          }
        }
      }
    }
  }
}
