resource "aws_kms_key" "alarms" {
  description             = "${var.project}-${var.environment} CloudWatch alarm topic key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.aws_account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudWatchAlarms"
        Effect    = "Allow"
        Principal = { Service = "cloudwatch.amazonaws.com" }
        Action    = ["kms:Decrypt", "kms:GenerateDataKey*"]
        Resource  = "*"
      },
      {
        Sid       = "AllowSNSService"
        Effect    = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action    = ["kms:Decrypt", "kms:GenerateDataKey*"]
        Resource  = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-alarms-cmk"
  })
}

resource "aws_kms_alias" "alarms" {
  name          = "alias/${var.project}-${var.environment}-alarms"
  target_key_id = aws_kms_key.alarms.key_id
}

resource "aws_sns_topic" "alarms" {
  name              = "${var.project}-${var.environment}-autoscaling-alarms"
  kms_master_key_id = aws_kms_key.alarms.arn

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-autoscaling-alarms"
  })
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "terraform_data" "enable_asg_metrics" {
  triggers_replace = [var.node_group_asg_name]

  provisioner "local-exec" {
    command = "aws autoscaling enable-metrics-collection --auto-scaling-group-name ${var.node_group_asg_name} --granularity 1Minute --region ${var.aws_region}"
  }
}

resource "aws_cloudwatch_metric_alarm" "nodegroup_at_max" {
  alarm_name        = "${var.project}-${var.environment}-nodegroup-at-max-capacity"
  alarm_description = "EKS node group ${var.node_group_asg_name} has scaled to its maximum of ${var.node_max_size} nodes; the cluster autoscaler cannot add more capacity. Pending pods may be unschedulable."

  namespace   = "AWS/AutoScaling"
  metric_name = "GroupInServiceInstances"
  dimensions  = { AutoScalingGroupName = var.node_group_asg_name }

  statistic           = "Maximum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.node_max_size
  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags       = var.tags
  depends_on = [terraform_data.enable_asg_metrics]
}

resource "aws_cloudwatch_metric_alarm" "nodegroup_cpu_high" {
  alarm_name        = "${var.project}-${var.environment}-nodegroup-cpu-high"
  alarm_description = "Average CPU across EKS node group ${var.node_group_asg_name} is >= ${var.cpu_high_threshold}% — sustained scale-up pressure on the cluster autoscaler."

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"
  dimensions  = { AutoScalingGroupName = var.node_group_asg_name }

  statistic           = "Average"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.cpu_high_threshold
  period              = 300
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  treat_missing_data  = "missing"

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = var.tags
}
