output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.this.arn
}

output "role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda.arn
}

output "log_group_name" {
  description = "Pod logs CloudWatch log group name"
  value       = aws_cloudwatch_log_group.pod_logs.name
}

output "security_group_id" {
  description = "Security group attached to the Lambda's VPC ENIs"
  value       = aws_security_group.lambda.id
}
