output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.this.arn
}

output "acm_certificate_validated_arn" {
  description = "ACM certificate ARN (after validation)"
  value       = aws_acm_certificate_validation.this.certificate_arn
}
