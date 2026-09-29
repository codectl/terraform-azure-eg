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
      storage_events = {
        enable_partitioning = true
      }
    }
  }
}

module "storage" {
  source  = "codectl/sa/azure"
  version = "~> 1.0"


  storage = {
    name                = module.naming.storage_account.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name

    blob_properties = {
      versioning_enabled       = true
      last_access_time_enabled = true
      change_feed_enabled      = true

      containers = {
        uploads = {
          metadata = {
            project    = "marketing"
            owner      = "marketing team"
            department = "digital"
            costcenter = "mkt-001"
            compliance = "gdpr"
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

    system_topics = {
      storage = {
        source_resource_id = module.storage.account.id
        topic_type         = "Microsoft.Storage.StorageAccounts"

        event_subscriptions = local.event_subscriptions
      }
    }
  }
}
