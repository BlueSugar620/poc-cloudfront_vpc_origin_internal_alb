# Certificate for CloudFront

resource "aws_acm_certificate" "cloudfront" { 
  domain_name = "*.${var.domain_name}"
  subject_alternative_names = ["${var.domain_name}"]
  validation_method = "DNS"
  provider = aws.virginia
}

resource "aws_route53_record" "cloudfront_validation" { 
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name = dvo.resource_record_name
      record = dvo.resource_record_value
      type = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.public.zone_id
  allow_overwrite = true
  name = each.value.name
  records = [each.value.record]
  type = each.value.type
  ttl = 60
}

resource "aws_acm_certificate_validation" "cloudfront" { 
  certificate_arn = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [ for record in aws_route53_record.cloudfront_validation : record.fqdn ]
  provider = aws.virginia

  depends_on = [aws_route53_record.cloudfront_validation]
}


# Certificate for ALB

resource "aws_acm_certificate" "alb" { 
  domain_name = "*.${var.domain_name}"
  subject_alternative_names = ["${var.domain_name}"]
  validation_method = "DNS"
}

resource "aws_route53_record" "alb_validation" { 
  for_each = {
    for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
      name = dvo.resource_record_name
      record = dvo.resource_record_value
      type = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.public.zone_id
  allow_overwrite = true
  name = each.value.name
  records = [each.value.record]
  type = each.value.type
  ttl = 60
}

resource "aws_acm_certificate_validation" "alb" { 
  certificate_arn = aws_acm_certificate.alb.arn
  validation_record_fqdns = [ for record in aws_route53_record.alb_validation : record.fqdn ]

  depends_on = [aws_route53_record.alb_validation]
}

