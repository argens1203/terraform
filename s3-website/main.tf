terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "ap-east-1"
}

resource "aws_s3_bucket" "web_server" {
  bucket = format("%s.%s", var.project_name, var.domain_name)

  tags = {
    Environment : var.env
  }
}

resource "aws_s3_bucket_acl" "web_host_acl" {
  bucket = aws_s3_bucket.web_server.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "web_server_config" {
  bucket = format("%s.%s", var.project_name, var.domain_name)
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "allow_public_access" {
  bucket = aws_s3_bucket.web_server.id
  policy = data.aws_iam_policy_document.allow_public_access.json
}

data "aws_iam_policy_document" "allow_public_access" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.web_server.arn}/*"
    ]
  }
}

locals {
  s3_origin_id = "s3Origin"
}

resource "aws_cloudfront_distribution" "web_distribution" {
  enabled = true
  aliases = [aws_s3_bucket.web_server.bucket]
  origin {
    domain_name = aws_s3_bucket_website_configuration.web_server_config.website_endpoint
    origin_id   = local.s3_origin_id
    custom_origin_config {
      https_port             = "443"
      http_port              = "80"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }
  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
    compress               = true
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
  }
  restrictions {
    geo_restriction {
      locations        = ["HK"]
      restriction_type = "whitelist"
    }
  }
  viewer_certificate {
    acm_certificate_arn = var.certificate_arn
    ssl_support_method = "sni-only"
  }
}

resource "aws_route53_zone" "iconic-fun" {
  name = "iconic.fun"
}

resource "aws_route53_record" "swap-dev" {
  zone_id = aws_route53_zone.iconic-fun.zone_id
  name    = format("%s.%s", var.project_name, var.domain_name)
  type    = "CNAME"
  ttl     = "300"
  records = [aws_cloudfront_distribution.web_distribution.domain_name]
}