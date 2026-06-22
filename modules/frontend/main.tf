# ─────────────────────────────────────────────────────────────────────────────
# CloudFront in front of the EKS frontend.
#
# The frontend runs as a pod (nginx) only — there is no S3 static bucket. The
# AWS Load Balancer Controller provisions the ALB from the Gateway API resources
# in the GitOps repo, and CloudFront uses that ALB as a custom origin.
#
# Request flow:
#   viewer -> CloudFront -> ALB (Host: <domain> forwarded) -> HTTPRoute
#     /     -> frontend nginx pod   (cached per nginx Cache-Control headers)
#     /api/* -> chat-service        (never cached)
#
# Forwarding the Host header is REQUIRED: the HTTPRoute only matches
# hostnames=[<domain>], and the ALB origin TLS cert is issued for <domain>, so
# the forwarded Host makes both the route match and the origin handshake succeed.
# ─────────────────────────────────────────────────────────────────────────────

locals {
  alb_origin_id = "alb-${var.environment}"
}

# Auto-discover the ALB the AWS Load Balancer Controller provisioned from the
# Gateway. The controller tags every load balancer it manages with the cluster
# name, and this cluster has exactly one internet-facing ALB — so this uniquely
# resolves it with no manual `kubectl get gateway` copy-paste. If it matches zero
# or multiple LBs, terraform fails loudly here rather than guessing.
data "aws_lb" "gateway" {
  tags = {
    "elbv2.k8s.aws/cluster" = var.eks_cluster_name
  }
}

resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project} ${var.environment} frontend CDN (ALB origin)"
  price_class     = "PriceClass_100"
  aliases         = [var.domain_name]
  http_version    = "http2and3"

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Single origin: the Gateway-provisioned ALB (auto-discovered above).
  origin {
    domain_name = data.aws_lb.gateway.dns_name
    origin_id   = local.alb_origin_id

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 120
      origin_keepalive_timeout = 60
    }
  }

  # Default behavior — static frontend served by the nginx pod. CloudFront caches
  # according to the Cache-Control headers nginx sends (html = no-cache, assets =
  # max-age=3600). default_ttl=0 means "do not cache" when no header is present.
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.alb_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      # Host is mandatory so the ALB HTTPRoute hostname match + origin TLS work.
      headers = ["Host"]
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 31536000
  }

  # /api/* — proxied straight through to the backend, never cached.
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.alb_origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = true
      headers      = ["Host", "Authorization", "Origin", "Referer", "Content-Type", "Accept"]
      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-cdn"
  })
}

# Point the apex domain at CloudFront. allow_overwrite takes ownership of any
# pre-existing record (e.g. a manual A record that previously pointed at the
# ALB). If external-dns manages this record from the HTTPRoute hostnames, remove
# those hostnames or exclude this record there to avoid a tug-of-war.
resource "aws_route53_record" "a" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "aaaa" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "AAAA"

  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

# ─────────────────────────── Origin lock-down ─────────────────────────────
# Security group that only accepts traffic from CloudFront's edge IP ranges,
# published by AWS as the "origin-facing" managed prefix list. Attach this SG
# to the ALB (via the Gateway LoadBalancerConfiguration.securityGroups field)
# so the cluster cannot be reached by hitting the raw ALB DNS name directly —
# all traffic must go through CloudFront.
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "alb_from_cloudfront" {
  name        = "${var.project}-${var.environment}-alb-cloudfront"
  description = "ALB ingress restricted to CloudFront origin-facing IPs"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-alb-cloudfront"
  })
}

resource "aws_vpc_security_group_ingress_rule" "https_from_cloudfront" {
  security_group_id = aws_security_group.alb_from_cloudfront.id
  description       = "HTTPS from CloudFront edge only"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
}

resource "aws_vpc_security_group_ingress_rule" "http_from_cloudfront" {
  security_group_id = aws_security_group.alb_from_cloudfront.id
  description       = "HTTP from CloudFront edge only (80 -> 443 redirect)"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
}

resource "aws_vpc_security_group_egress_rule" "alb_all_out" {
  security_group_id = aws_security_group.alb_from_cloudfront.id
  description       = "Allow ALB to reach backend targets"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
