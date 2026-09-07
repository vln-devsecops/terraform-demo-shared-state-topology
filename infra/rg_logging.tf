# devops-owned shared scaffolding: a central S3 bucket that every app
# environment's site bucket delivers its access logs to (see fn_site.tf).

resource "aws_s3_bucket" "shared_logs" {
  count = local.is_devops ? 1 : 0

  bucket = "s3-${local.app_name}-devops-${data.aws_caller_identity.current.account_id}-logs"

  tags = {
    rg = "logging"
  }
}

resource "aws_s3_bucket_public_access_block" "shared_logs" {
  count = local.is_devops ? 1 : 0

  bucket = aws_s3_bucket.shared_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket-policy log delivery (not the legacy log-delivery ACL): S3 defaults
# new buckets to BucketOwnerEnforced, which disables ACLs entirely.
resource "aws_s3_bucket_policy" "shared_logs" {
  count = local.is_devops ? 1 : 0

  bucket = aws_s3_bucket.shared_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "S3ServerAccessLogsPolicy"
      Effect    = "Allow"
      Principal = { Service = "logging.s3.amazonaws.com" }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.shared_logs[0].arn}/s3-access/*"
      Condition = {
        ArnLike = {
          "aws:SourceArn" = "arn:aws:s3:::s3-${local.app_name}-*-${data.aws_caller_identity.current.account_id}-site"
        }
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }]
  })
}
