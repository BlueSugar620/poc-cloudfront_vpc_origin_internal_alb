# ALB Access Logs S3 Bucket Policy
data "aws_iam_policy_document" "alb_logs" {
  statement {
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.alb_logs.id}",
      "arn:aws:s3:::${aws_s3_bucket.alb_logs.id}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["582318560864"]
    }
  }

  depends_on = [aws_s3_bucket.alb_logs]
}


# Public Host Zone
data "aws_route53_zone" "public" {
  name = var.domain_name
}


# CloudFront SecurityGroup
data "aws_security_group" "vpc_origin" {
  filter {
    name   = "group-name"
    values = ["CloudFront-VPCOrigins-Service-SG"]
  }

  filter {
    name   = "vpc-id"
    values = [aws_vpc.main.id]
  }

  depends_on = [null_resource.cloudfront_update_trigger]
}
