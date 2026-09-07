mock_provider "aws" {
  override_during = plan
}

run "devops_owns_shared_logging_only" {
  command = plan

  variables {
    deployment_environment = "devops"
    selected_environment   = "devops"
  }

  override_data {
    target = data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/terraform-test"
      id         = "123456789012"
      user_id    = "AIDAEXAMPLE123456789"
    }
  }

  assert {
    condition     = length(aws_s3_bucket.shared_logs) == 1
    error_message = "devops must own the shared logs bucket"
  }

  assert {
    condition     = length(aws_s3_bucket.site) == 0
    error_message = "devops must not own an app site bucket"
  }
}

run "dev_owns_site_and_reads_shared_state" {
  command = plan

  variables {
    deployment_environment = "dev"
    selected_environment   = "dev"
    shared_state_bucket    = "mock-shared-state-bucket"
    shared_state_region    = "us-east-1"
    # Ownership-only check: gates off the real terraform_remote_state read so
    # this plans without a devops state having actually been applied
    # anywhere (see data.tf and the guidance runbook's troubleshooting
    # section on stage=bootstrap).
    stage = "bootstrap"
  }

  override_data {
    target = data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/terraform-test"
      id         = "123456789012"
      user_id    = "AIDAEXAMPLE123456789"
    }
  }

  assert {
    condition     = length(aws_s3_bucket.site) == 1
    error_message = "dev must own its own site bucket"
  }

  assert {
    condition     = length(aws_s3_bucket.shared_logs) == 0
    error_message = "dev must not own the shared logs bucket"
  }

  assert {
    condition     = length(data.terraform_remote_state.devops) == 0
    error_message = "stage=bootstrap must gate off the terraform_remote_state read"
  }
}

run "prod_owns_site_and_reads_shared_state" {
  command = plan

  variables {
    deployment_environment = "prod"
    selected_environment   = "prod"
    shared_state_bucket    = "mock-shared-state-bucket"
    shared_state_region    = "us-east-1"
    stage                  = "bootstrap"
  }

  override_data {
    target = data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/terraform-test"
      id         = "123456789012"
      user_id    = "AIDAEXAMPLE123456789"
    }
  }

  assert {
    condition     = length(aws_s3_bucket.site) == 1
    error_message = "prod must own its own site bucket"
  }

  assert {
    condition     = length(aws_s3_bucket.shared_logs) == 0
    error_message = "prod must not own the shared logs bucket"
  }

  assert {
    condition     = length(data.terraform_remote_state.devops) == 0
    error_message = "stage=bootstrap must gate off the terraform_remote_state read"
  }
}
