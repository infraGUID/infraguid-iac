output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (use for cache invalidations on deploy)"
  value       = aws_cloudfront_distribution.this.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID (for Route 53 alias)"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "cloudfront_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.this.arn
}

output "alb_security_group_id" {
  description = "Security group (CloudFront-only) to attach to the ALB via the Gateway LoadBalancerConfiguration.securityGroups field"
  value       = aws_security_group.alb_from_cloudfront.id
}
