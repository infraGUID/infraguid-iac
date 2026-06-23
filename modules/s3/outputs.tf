output "documents_bucket_name" {
  description = "Documents bucket name"
  value       = aws_s3_bucket.this["documents"].id
}

output "documents_bucket_arn" {
  description = "Documents bucket ARN"
  value       = aws_s3_bucket.this["documents"].arn
}

output "knowledge_base_bucket_name" {
  description = "Knowledge base bucket name"
  value       = aws_s3_bucket.this["knowledge_base"].id
}

output "knowledge_base_bucket_arn" {
  description = "Knowledge base bucket ARN"
  value       = aws_s3_bucket.this["knowledge_base"].arn
}

output "lambda_artifacts_bucket_name" {
  description = "Lambda artifacts bucket name"
  value       = aws_s3_bucket.this["lambda_artifacts"].id
}

output "lambda_artifacts_bucket_arn" {
  description = "Lambda artifacts bucket ARN"
  value       = aws_s3_bucket.this["lambda_artifacts"].arn
}

output "replica_bucket_arns" {
  description = "ARNs of DR replica buckets keyed by logical name. Empty map when enable_replication = false."
  value       = { for k, b in aws_s3_bucket.replica : k => b.arn }
}
