# S3 Bucket for Static Files
resource "aws_s3_bucket" "static" {
  bucket = var.bucket_name

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-s3"
    }
  )
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "static" {
  bucket = aws_s3_bucket.static.id
  versioning_configuration {
    status = var.versioning ? "Enabled" : "Suspended"
  }
}

# S3 Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "static" {
  bucket = aws_s3_bucket.static.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "static" {
  bucket = aws_s3_bucket.static.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "static" {
  bucket = aws_s3_bucket.static.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

# S3 Bucket Logging
resource "aws_s3_bucket_logging" "static" {
  bucket = aws_s3_bucket.static.id

  target_bucket = aws_s3_bucket.static.id
  target_prefix = "log/"
}

# S3 Bucket Policy (example for CloudFront access)
resource "aws_s3_bucket_policy" "static" {
  bucket = aws_s3_bucket.static.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyUnencryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.static.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      }
    ]
  })
}

# CloudWatch Alarm - Bucket Size
resource "aws_cloudwatch_metric_alarm" "s3_size" {
  alarm_name          = "${var.project_name}-${var.environment}-s3-size"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = "86400"
  statistic           = "Average"
  threshold           = "107374182400" # 100GB in bytes
  alarm_description   = "This metric monitors S3 bucket size"

  dimensions = {
    BucketName = aws_s3_bucket.static.id
    StorageType = "StandardStorage"
  }
}

# CloudWatch Alarm - Number of Objects
resource "aws_cloudwatch_metric_alarm" "s3_objects" {
  alarm_name          = "${var.project_name}-${var.environment}-s3-objects"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = "86400"
  statistic           = "Average"
  threshold           = "1000000"
  alarm_description   = "This metric monitors S3 number of objects"

  dimensions = {
    BucketName = aws_s3_bucket.static.id
    StorageType = "AllStorageTypes"
  }
}
