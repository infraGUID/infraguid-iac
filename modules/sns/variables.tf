variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alert_email" {
  description = "Admin email for alert notifications (empty to skip subscription)"
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "KMS key id/alias for topic encryption. AWS-managed SNS key avoids key-policy issues with email delivery."
  type        = string
  default     = "alias/aws/sns"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
