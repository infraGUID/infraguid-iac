variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for queue encryption (SSE-KMS)"
  type        = string
}

variable "visibility_timeout_seconds" {
  description = "How long a received message stays invisible. Must exceed the worst-case ingestion run so an in-flight job is not redelivered."
  type        = number
  default     = 900 # 15 minutes
}

variable "message_retention_seconds" {
  description = "How long an unconsumed message is retained on the main queue."
  type        = number
  default     = 86400 # 1 day
}

variable "dlq_retention_seconds" {
  description = "How long a failed message is retained in the dead-letter queue."
  type        = number
  default     = 1209600 # 14 days (max)
}

variable "receive_wait_time_seconds" {
  description = "Long-poll wait time (0-20s). 20 minimizes empty receives."
  type        = number
  default     = 20
}

variable "max_receive_count" {
  description = "Receives before a message is moved to the dead-letter queue."
  type        = number
  default     = 3
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
