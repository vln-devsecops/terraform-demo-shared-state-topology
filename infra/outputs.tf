output "shared_logs_bucket_name" {
  value = local.is_devops ? aws_s3_bucket.shared_logs[0].bucket : null
}

output "shared_logs_bucket_arn" {
  value = local.is_devops ? aws_s3_bucket.shared_logs[0].arn : null
}

output "site_endpoint" {
  value = local.is_app ? aws_s3_bucket_website_configuration.site[0].website_endpoint : null
}
