# dev/prod-owned: a public static-website bucket serving a "hello world" page,
# logging its access to the shared devops bucket (rg_logging.tf) via the
# shared-state contract instead of recreating its own logging bucket.

resource "aws_s3_bucket" "site" {
  count = local.is_app ? 1 : 0

  bucket = "s3-${local.app_name}-${var.deployment_environment}-${data.aws_caller_identity.current.account_id}-site"

  tags = {
    feature = "site"
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  count = local.is_app ? 1 : 0

  bucket = aws_s3_bucket.site[0].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "site" {
  count = local.is_app ? 1 : 0

  bucket = aws_s3_bucket.site[0].id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "site" {
  count = local.is_app ? 1 : 0

  bucket = aws_s3_bucket.site[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.site[0].arn}/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.site]
}

resource "aws_s3_object" "index" {
  count = local.is_app ? 1 : 0

  bucket       = aws_s3_bucket.site[0].id
  key          = "index.html"
  content_type = "text/html"
  content      = "<html><body><h1>Hello world from ${var.deployment_environment}</h1></body></html>"
}

resource "aws_s3_bucket_logging" "site" {
  count = local.is_app && var.stage != "bootstrap" ? 1 : 0

  bucket = aws_s3_bucket.site[0].id

  target_bucket = data.terraform_remote_state.devops[0].outputs.shared_logs_bucket_name
  target_prefix = "s3-access/${var.deployment_environment}/"
}
