# CloudFront

resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name = var.domain_name
    origin_id   = aws_lb.main.id
    vpc_origin_config {
      vpc_origin_id = aws_cloudfront_vpc_origin.alb.id
    }
  }
  enabled = true
  aliases = ["${var.domain_name}", "*.${var.domain_name}"]

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = aws_lb.main.id

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 10
    max_ttl                = 60

    cache_policy_id          = aws_cloudfront_cache_policy.pass_host_cache.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.pass_host.id
  }

  restrictions {
    geo_restriction {
      locations        = ["JP"]
      restriction_type = "whitelist"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate_validation.cloudfront.certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

resource "aws_cloudfront_origin_request_policy" "pass_host" {
  name = "pass-host-header"

  cookies_config {
    cookie_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "none"
  }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Host"]
    }
  }
}

resource "aws_cloudfront_cache_policy" "pass_host_cache" {
  name = "pass-host-cache"

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true

    cookies_config {
      cookie_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Host"]
      }
    }
  }
}

resource "aws_cloudfront_vpc_origin" "alb" {
  vpc_origin_endpoint_config {
    name                   = "alb-vpc-origin"
    arn                    = aws_lb.main.arn
    http_port              = 80
    https_port             = 443
    origin_protocol_policy = "https-only"

    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }
}

## resource "aws_lambda_function" "edge" {
##   provider = aws.virginia
##   filename = data.archive_file.lambda_edge.output_path
##   source_code_hash = data.archive_file.lambda_edge.output_base64sha256
##   function_name = "lambda-edge"
##   role = aws_iam_role.lambda_edge_role
##   handler = "lambda.lambda_handler"
##   publish = true
##   runtime = "nodejs14.x"
## }

resource "null_resource" "cloudfront_update_trigger" {
  triggers = {
    cloudfront_id = aws_cloudfront_distribution.main.id
  }

  depends_on = [aws_cloudfront_distribution.main, aws_cloudfront_vpc_origin.alb]
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_cloudfront" {
  security_group_id            = aws_security_group.alb.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = data.aws_security_group.vpc_origin.id

  lifecycle {
    create_before_destroy = true
    replace_triggered_by  = [null_resource.cloudfront_update_trigger]
  }

  depends_on = [null_resource.cloudfront_update_trigger, data.aws_security_group.vpc_origin]
}


