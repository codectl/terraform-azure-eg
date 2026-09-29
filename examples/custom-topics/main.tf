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

    topics = {
      notifications = {
        name                = "user-notifications"
        enable_partitioning = true
        subscriptions = {
          premium = {
            name               = "premium-users"
            max_delivery_count = 10
            sql_filter         = "userType = 'premium'"
          }
          enterprise = {
            name               = "enterprise-users"
            max_delivery_count = 10
            sql_filter         = "userType = 'enterprise'"
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
    resource_group_name = module.rg.groups.demo.name
    location            = module.rg.groups.demo.location

    custom_topics = {
      notifications = {
        name                          = module.naming.eventgrid_topic.name_unique
        input_schema                  = "CloudEventSchemaV1_0"
        public_network_access_enabled = true
        event_subscriptions           = local.event_subscriptions

        inbound_ip_rule = [
          {
            ip_mask = "10.0.0.0/16"
            action  = "Allow"
          },
          {
            ip_mask = "192.168.1.0/24"
            action  = "Allow"
          }
        ]
      }
    }
  }
}
