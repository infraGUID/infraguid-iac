# ─────────────────────────── Alarm SNS topic ──────────────────────────────
# A DEDICATED topic for CloudWatch alarms, separate from the log-intel alerts
# topic. Reason: CloudWatch cannot publish to a topic encrypted with the
# AWS-managed `alias/aws/sns` key (that key's policy can't be edited to grant
# the CloudWatch service principal), so alarm notifications would silently fail.
# This topic uses a dedicated customer-managed key whose policy explicitly
# grants both CloudWatch and SNS, which is the supported way to deliver alarm
# notifications over an encrypted topic.

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

# Email subscription — requires manual confirmation from the inbox after apply.
resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ───────────────────── Enable ASG group metrics ────────────────────────────
# EKS-managed node group ASGs do NOT publish AWS/AutoScaling group metrics
# (GroupInServiceInstances, GroupDesiredCapacity, …) by default, so the
# at-capacity alarm below would sit in INSUFFICIENT_DATA forever. There is no
# Terraform resource to toggle metrics on an ASG we don't manage, so enable it
# via the AWS CLI. The call is idempotent and re-runs only if the ASG name
# changes (e.g. node group recreated).
resource "terraform_data" "enable_asg_metrics" {
  triggers_replace = [var.node_group_asg_name]

  provisioner "local-exec" {
    command = "aws autoscaling enable-metrics-collection --auto-scaling-group-name ${var.node_group_asg_name} --granularity 1Minute --region ${var.aws_region}"
  }
}

# ───────────────────────────── Alarms ─────────────────────────────────────
# Cluster autoscaling at its ceiling: the node group has scaled all the way to
# node_max_size and can't add more nodes, so newly-scheduled pods may stay
# Pending. This is the primary "autoscaling needs attention" signal.
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

# Scale-up pressure: sustained high CPU across the node group. Uses the
# per-instance AWS/EC2 CPUUtilization metric aggregated by ASG, which EKS nodes
# emit by default (5-minute granularity), so this works independently of the
# group-metrics enabler above.
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
