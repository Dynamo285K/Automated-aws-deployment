resource "aws_s3_bucket" "app" {
  bucket_prefix = "automated-aws-app-"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket                  = aws_s3_bucket.app.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "hello" {
  bucket  = aws_s3_bucket.app.id
  key     = "hello.txt"
  content = "Hello from s3 via IAM role!"
}