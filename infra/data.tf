data "aws_caller_identity" "current" {}

data "terraform_remote_state" "devops" {
  count = local.is_app && var.stage != "bootstrap" ? 1 : 0

  backend = "s3"

  config = {
    bucket = var.shared_state_bucket
    key    = var.shared_state_key
    region = var.shared_state_region
  }
}
