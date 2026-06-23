output "app_url" {
  description = "Application URL"
  value       = "https://${var.domain_name}"
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "update_kubeconfig_command" {
  description = "Run this to configure kubectl for the cluster"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

output "oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  value       = module.eks.oidc_provider_arn
}

output "ecr_registry_url" {
  description = "ECR registry base URL"
  value       = module.ecr.registry_url
}

output "ecr_repository_urls" {
  description = "Map of service => ECR repository URL"
  value       = module.ecr.repository_urls
}

output "irsa_app_role_arn" {
  description = "IRSA role ARN for application pods"
  value       = module.irsa.app_role_arn
}

output "irsa_alb_controller_role_arn" {
  description = "IRSA role ARN for the AWS Load Balancer Controller"
  value       = module.irsa.alb_controller_role_arn
}

output "irsa_external_secrets_role_arn" {
  description = "IRSA role ARN for External Secrets"
  value       = module.irsa.external_secrets_role_arn
}

output "irsa_fluent_bit_role_arn" {
  description = "IRSA role ARN for Fluent Bit"
  value       = module.irsa.fluent_bit_role_arn
}

output "irsa_ebs_csi_role_arn" {
  description = "IRSA role ARN for the EBS CSI driver"
  value       = module.irsa.ebs_csi_role_arn
}

output "irsa_cluster_autoscaler_role_arn" {
  description = "IRSA role ARN for the Cluster Autoscaler"
  value       = module.irsa.cluster_autoscaler_role_arn
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.endpoint
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_app_client_id" {
  description = "Cognito App Client ID"
  value       = module.cognito.app_client_id
}

output "secret_name" {
  description = "Secrets Manager secret name"
  value       = module.secrets.secret_name
}

output "documents_bucket_name" {
  description = "Documents S3 bucket name"
  value       = module.s3.documents_bucket_name
}

output "knowledge_base_bucket_name" {
  description = "Knowledge base S3 bucket name"
  value       = module.s3.knowledge_base_bucket_name
}

output "lambda_artifacts_bucket_name" {
  description = "Lambda artifacts S3 bucket name"
  value       = module.s3.lambda_artifacts_bucket_name
}

output "acm_certificate_arn" {
  description = "Validated ACM certificate ARN for the ALB Ingress"
  value       = module.dns.acm_certificate_validated_arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (use for cache invalidations on deploy)"
  value       = var.enable_cloudfront ? module.frontend[0].cloudfront_distribution_id : null
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = var.enable_cloudfront ? module.frontend[0].cloudfront_domain_name : null
}

output "alb_cloudfront_security_group_id" {
  description = "CloudFront-only SG to attach to the ALB Gateway (LoadBalancerConfiguration.securityGroups)"
  value       = var.enable_cloudfront ? module.frontend[0].alb_security_group_id : null
}

output "alerts_topic_arn" {
  description = "SNS alerts topic ARN"
  value       = module.sns.topic_arn
}

output "autoscaling_alarm_topic_arn" {
  description = "SNS topic ARN that the EKS autoscaling CloudWatch alarms publish to"
  value       = module.cloudwatch.alarm_topic_arn
}

output "sqs_ingestion_queue_url" {
  description = "Ingestion SQS queue URL (injected into the app secret as SQS_INGESTION_QUEUE_URL)"
  value       = module.sqs.ingestion_queue_url
}

output "sqs_ingestion_dlq_url" {
  description = "Ingestion dead-letter queue URL"
  value       = module.sqs.ingestion_dlq_url
}

output "log_intel_function_name" {
  description = "Log Intelligence Lambda function name"
  value       = var.enable_log_intel ? module.log_intel_lambda[0].function_name : null
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "estimated_monthly_cost_usd" {
  description = "Rough estimated total monthly AWS cost in USD (us-east-1, on-demand)"
  value       = local.cost_total_monthly
}

output "cost_breakdown_usd" {
  description = "Monthly cost estimate (USD) broken down by infrastructure component"
  value       = local.cost_breakdown
}
