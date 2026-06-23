variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  type        = string
}

variable "oidc_provider_url" {
  description = "EKS OIDC issuer URL (no https:// prefix)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name (used to scope Cluster Autoscaler scaling permissions)"
  type        = string
}

variable "app_namespace" {
  description = "Kubernetes namespace the application pods run in"
  type        = string
  default     = "infraguid"
}

variable "app_service_account" {
  description = "Kubernetes service account name used by application pods"
  type        = string
  default     = "infraguid-app"
}

variable "kms_key_arn" {
  description = "KMS key ARN"
  type        = string
}

variable "secret_arn" {
  description = "Secrets Manager app secret ARN"
  type        = string
}

variable "documents_bucket_arn" {
  description = "Documents bucket ARN"
  type        = string
}

variable "knowledge_base_bucket_arn" {
  description = "Knowledge base bucket ARN"
  type        = string
}

variable "ingestion_queue_arns" {
  description = "ARNs of the ingestion SQS queue(s) the app may produce to / consume from"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
