output "ingestion_queue_url" {
  description = "URL of the ingestion SQS queue (set as SQS_INGESTION_QUEUE_URL)"
  value       = aws_sqs_queue.ingestion.url
}

output "ingestion_queue_arn" {
  description = "ARN of the ingestion SQS queue"
  value       = aws_sqs_queue.ingestion.arn
}

output "ingestion_dlq_url" {
  description = "URL of the ingestion dead-letter queue"
  value       = aws_sqs_queue.ingestion_dlq.url
}

output "ingestion_dlq_arn" {
  description = "ARN of the ingestion dead-letter queue"
  value       = aws_sqs_queue.ingestion_dlq.arn
}
