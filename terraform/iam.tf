# Trust policy: only the EC2 service may assume this role
data "aws_iam_policy_document" "app_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "app-server-role"
  assume_role_policy = data.aws_iam_policy_document.app_assume_role.json
}

data "aws_iam_policy_document" "app_s3_read" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.app.arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.app.arn}/*"]
  }
}

resource "aws_iam_role_policy" "app_s3_read" {
  name   = "app-s3-read"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app_s3_read.json
}

resource "aws_iam_instance_profile" "app" {
  name = "app-server-profile"
  role = aws_iam_role.app.name
}