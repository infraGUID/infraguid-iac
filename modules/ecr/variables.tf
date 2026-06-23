variable "namespace" {
  description = "ECR repository namespace prefix (e.g. infragui)"
  type        = string
  default     = "infragui"
}

variable "repositories" {
  description = "Service names to create repositories for"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS key ARN for image encryption"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
