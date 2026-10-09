output "bucket_name" {
  description = "Returns the name of the s3 state bucket"
  value       = aws_s3_bucket.tfstate.bucket
}