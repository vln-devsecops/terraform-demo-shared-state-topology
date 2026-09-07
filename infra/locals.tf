locals {
  app_name = "shared-state-demo"

  is_devops = var.deployment_environment == "devops"
  is_app    = !local.is_devops
}
