variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region (used by the ASG metrics-collection enabler)"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID (used in the alarm-topic KMS key policy)"
  type        = string
}

variable "alert_email" {
  description = "Email subscribed to the autoscaling alarm topic (empty to skip the subscription)"
  type        = string
  default     = ""
}

variable "node_group_asg_name" {
  description = "Name of the EKS managed node group's Auto Scaling Group (target of the autoscaling alarms)"
  type        = string
}

variable "node_max_size" {
  description = "Maximum node count of the node group. The at-capacity alarm fires when in-service nodes reach this."
  type        = number
}

variable "cpu_high_threshold" {
  description = "Average node-group CPU % that signals scale-up pressure"
  type        = number
  default     = 80
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
