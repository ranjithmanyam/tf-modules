############################
# S3
############################

resource "aws_s3_bucket" "assets" {
  bucket = var.project_name
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################
# ACM (us-east-1)
############################

resource "aws_acm_certificate" "cdn" {
  provider          = aws.use1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "cloudflare_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cdn.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  type    = each.value.type
  value   = each.value.value
  ttl     = 300
  proxied = false
}

resource "aws_acm_certificate_validation" "cdn" {
  provider = aws.use1

  certificate_arn = aws_acm_certificate.cdn.arn
  validation_record_fqdns = [
    for r in cloudflare_record.acm_validation : r.hostname
  ]
}

############################
# CloudFront
############################

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled     = true
  aliases     = [var.domain_name]
  price_class = var.price_class
  tags        = var.tags

  origin {
    domain_name              = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_id                = "s3-assets"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-assets"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    compress = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cdn.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

############################
# S3 Bucket Policy (CloudFront only)
############################

resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.assets.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
        }
      }
    }]
  })
}

############################
# Cloudflare DNS
############################

resource "cloudflare_record" "cdn" {
  zone_id = var.cloudflare_zone_id
  name    = trimsuffix(var.domain_name, ".${data.cloudflare_zone.zone.name}")
  type    = "CNAME"
  value   = aws_cloudfront_distribution.cdn.domain_name
  ttl     = 300
  proxied = false
}

data "cloudflare_zone" "zone" {
  zone_id = var.cloudflare_zone_id
}
