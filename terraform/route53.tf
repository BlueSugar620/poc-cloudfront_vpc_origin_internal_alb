# Private Host Zone

resource "aws_route53_zone" "private" { 
  name = var.domain_name
  
  vpc {
    vpc_id = aws_vpc.main.id
  }
}


# Record for CloudFront

resource "aws_route53_record" "cloudfront" { 
  zone_id = data.aws_route53_zone.public.zone_id
  name = var.domain_name
  type = "A"
  allow_overwrite = true

  alias {
    name = aws_cloudfront_distribution.main.domain_name
    zone_id = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "wildcard_cloudfront" { 
  zone_id = data.aws_route53_zone.public.zone_id
  name = "*.${var.domain_name}"
  type = "A"
  allow_overwrite = true

  alias {
    name = aws_cloudfront_distribution.main.domain_name
    zone_id = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = true
  }
}


# Record for ALB

resource "aws_route53_record" "alb" { 
  zone_id = aws_route53_zone.private.zone_id
  name = "var.domain_name"
  type = "A"
  allow_overwrite = true

  alias {
    name = aws_lb.main.dns_name
    zone_id = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "wildcard_alb" { 
  zone_id = aws_route53_zone.private.zone_id
  name = "*.${var.domain_name}"
  type = "A"
  allow_overwrite = true

  alias {
    name = aws_lb.main.dns_name
    zone_id = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
