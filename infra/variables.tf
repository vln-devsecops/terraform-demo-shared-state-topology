variable "deployment_environment" {
  type = string

  validation {
    condition     = contains(["devops", "dev", "prod"], var.deployment_environment)
    error_message = "deployment_environment must be one of: devops, dev, prod."
  }
}

variable "selected_environment" {
  type = string

  validation {
    condition     = var.selected_environment == var.deployment_environment
    error_message = "selected_environment (written by ./bootstrap) must match deployment_environment (from the environment's terraform.tfvars)."
  }
}

variable "shared_state_bucket" {
  type    = string
  default = null
}

variable "shared_state_region" {
  type    = string
  default = null
}

variable "shared_state_key" {
  type    = string
  default = "terraform-demo-shared-state-topology/infra/devops/terraform.tfstate"
}

# Set to "bootstrap" only from `terraform test` to gate off the real
# terraform_remote_state read (see data.tf) - ownership tests plan dev/prod
# without a devops state having actually been applied anywhere. Every real
# apply uses the "final" default.
variable "stage" {
  type    = string
  default = "final"
}
