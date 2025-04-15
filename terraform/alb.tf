# ALB

resource "aws_lb" "main" { 
  name = "alb-vpc-origin"
  load_balancer_type = "application"
  internal = true
  idle_timeout = 60

  subnets = [for subnet in aws_subnet.private : subnet.id]
  security_groups = [aws_security_group.alb.id]

  access_logs {
    bucket = aws_s3_bucket.alb_logs.id
    enabled = true
    prefix = "alb-logs"
  }
}

resource "aws_lb_listener" "https" { 
  load_balancer_arn = aws_lb.main.arn
  port = 443
  protocol = "HTTPS"
  certificate_arn = aws_acm_certificate.alb.arn
  ssl_policy = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"
    
    fixed_response {
      content_type = "text/plain"
      message_body = "This is HTTPS response from ALB."
      status_code = 200
    }
  }

  depends_on = [aws_acm_certificate_validation.alb, aws_acm_certificate.alb]
}

resource "aws_lb_listener_rule" "one" { 
  listener_arn = aws_lb_listener.https.arn
  priority = 100

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "This is ONE."
      status_code = 200
    }
  }

  condition {
    host_header {
      values = ["one.${var.domain_name}"]
    }
  }
}

resource "aws_lb_listener_rule" "two" { 
  listener_arn = aws_lb_listener.https.arn
  priority = 99

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "This is TWO."
      status_code = 200
    }
  }

  condition {
    host_header {
      values = ["two.${var.domain_name}"]
    }
  }
}


# ALB Access Logs Bucket

resource "aws_s3_bucket" "alb_logs" { 
  bucket = "alb-vpc-origin-internal-alb"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "alb_logs" { 
  bucket = aws_s3_bucket.alb_logs.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = data.aws_iam_policy_document.alb_logs.json
}


# Security Group

resource "aws_security_group" "alb" {
  name   = "vpc-origin-internal-alb"
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_egress_rule" "alb" { 
  security_group_id = aws_security_group.alb.id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

