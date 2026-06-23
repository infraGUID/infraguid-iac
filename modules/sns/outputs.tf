output "topic_arn" {
  description = "SNS alerts topic ARN"
  value       = aws_sns_topic.alerts.arn
}

output "topic_name" {
  description = "SNS alerts topic name"
  value       = aws_sns_topic.alerts.name
}
