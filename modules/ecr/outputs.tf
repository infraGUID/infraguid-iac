output "repository_urls" {
  description = "Map of service name => ECR repository URL"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of service name => ECR repository ARN"
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}

output "registry_url" {
  description = "ECR registry base URL (account.dkr.ecr.region.amazonaws.com)"
  value       = length(aws_ecr_repository.this) > 0 ? split("/", values(aws_ecr_repository.this)[0].repository_url)[0] : ""
}
