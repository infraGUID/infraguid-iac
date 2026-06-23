output "app_role_arn" {
  description = "IRSA role ARN for application pods"
  value       = aws_iam_role.app.arn
}

output "alb_controller_role_arn" {
  description = "IRSA role ARN for the AWS Load Balancer Controller"
  value       = aws_iam_role.alb_controller.arn
}

output "external_secrets_role_arn" {
  description = "IRSA role ARN for External Secrets"
  value       = aws_iam_role.external_secrets.arn
}

output "fluent_bit_role_arn" {
  description = "IRSA role ARN for Fluent Bit"
  value       = aws_iam_role.fluent_bit.arn
}

output "ebs_csi_role_arn" {
  description = "IRSA role ARN for the EBS CSI driver"
  value       = aws_iam_role.ebs_csi.arn
}

output "cluster_autoscaler_role_arn" {
  description = "IRSA role ARN for the Cluster Autoscaler"
  value       = aws_iam_role.cluster_autoscaler.arn
}
