output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.static.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.static.arn
}

output "bucket_region" {
  description = "S3 bucket region"
  value       = aws_s3_bucket.static.region
}
