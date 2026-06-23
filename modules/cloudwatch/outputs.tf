output "alarm_topic_arn" {
  description = "SNS topic ARN that the autoscaling alarms publish to"
  value       = aws_sns_topic.alarms.arn
}

output "at_max_alarm_name" {
  description = "Name of the node-group-at-max-capacity alarm"
  value       = aws_cloudwatch_metric_alarm.nodegroup_at_max.alarm_name
}

output "cpu_high_alarm_name" {
  description = "Name of the node-group CPU-high alarm"
  value       = aws_cloudwatch_metric_alarm.nodegroup_cpu_high.alarm_name
}
