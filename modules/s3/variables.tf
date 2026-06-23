variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID (used to keep bucket names globally unique)"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for bucket encryption"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "enable_replication" {
  description = "Enable cross-region replication to the DR region"
  type        = bool
  default     = false
}

variable "dr_kms_key_arn" {
  description = "KMS key ARN in the DR region used to encrypt replica objects. Required when enable_replication = true."
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "dr_region" {
  description = "DR AWS region for replica buckets"
  type        = string
  default     = "ap-south-1"
}
