variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID for key policy"
  type        = string
}

variable "aws_region" {
  description = "AWS region where this KMS key will be used (drives the RDS ViaService condition)"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
