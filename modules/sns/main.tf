# SNS topic for the Log Intelligence Agent alerts (notify-only to admin).
resource "aws_sns_topic" "alerts" {
  name              = "${var.project}-${var.environment}-alerts"
  kms_master_key_id = var.kms_key_id

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-alerts"
  })
}

# Email subscription — requires manual confirmation from the inbox after apply.
resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
