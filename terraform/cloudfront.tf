# CloudFront

resource "aws_cloudfront_distribution" "main" { 
  origin {
    domain_name = "alb.${var.domain_name}"
    origin_id = aws_lb.main.id
    vpc_origin_config {
      vpc_origin_id = aws_cloudfront_vpc_origin.alb.id
    } 
  }
  enabled = true
  aliases = ["cloudfront.${var.domain_name}"]

  default_cache_behavior {
    allowed_methods = ["HEAD", "GET"]
    cached_methods = ["HEAD", "GET"]
    target_origin_id = aws_lb.main.id
    
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = ["*"]
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl = 0
    default_ttl = 10
    max_ttl = 60
  }

  restrictions {
    geo_restriction {
      locations = ["JP"]
      restriction_type = "whitelist"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn = aws_acm_certificate_validation.cloudfront.certificate_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_cloudfront_vpc_origin" "alb" { 
  vpc_origin_endpoint_config {
    name = "alb-vpc-origin"
    arn = aws_lb.main.arn
    http_port = 80
    https_port = 443
    origin_protocol_policy = "https-only"

    origin_ssl_protocols {
      items = ["TLSv1.2"]
      quantity = 1
    }
  }
}

resource "null_resource" "cloudfront_update_trigger" { 
  triggers = {
    cloudfront_id = aws_cloudfront_distribution.main.id
  } 

  depends_on = [aws_cloudfront_distribution.main, aws_cloudfront_vpc_origin.alb]
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_cloudfront" { 
  security_group_id = aws_security_group.alb.id
  from_port = 443
  to_port = 443
  ip_protocol = "tcp"
  referenced_security_group_id = data.aws_security_group.vpc_origin.id

  lifecycle {
    create_before_destroy = true
    replace_triggered_by = [null_resource.cloudfront_update_trigger]
  }

  depends_on = [null_resource.cloudfront_update_trigger, data.aws_security_group.vpc_origin]
}
