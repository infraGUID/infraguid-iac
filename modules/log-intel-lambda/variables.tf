variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the Lambda ENIs"
  type        = list(string)
}

variable "sns_topic_arn" {
  description = "SNS alerts topic ARN"
  type        = string
}

variable "secret_arn" {
  description = "Secrets Manager secret ARN (holds ArgoCD token when correlation enabled)"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group Fluent Bit ships pod logs to"
  type        = string
  default     = "/infraguid/prod/pod-logs"
}

variable "log_retention_days" {
  description = "Retention for the pod-logs log group"
  type        = number
  default     = 14
}

variable "anomaly_filter_pattern" {
  description = <<-EOT
    CloudWatch Logs filter pattern that triggers the Lambda (coarse pre-filter).
    This is a CURATED SUBSET of the authoritative classifier ANOMALY_PATTERNS in
    services/log-intel-lambda/collect.py (which carries the full ~39-signature
    set). The subset stays well under CloudWatch's 1024-char filter limit and
    omits the noisiest/most-redundant generic terms (e.g. "Unhealthy",
    "connection refused", "context deadline exceeded") to control invocation
    cost; the classifier still catches those when they co-occur in a batch.
  EOT
  type        = string
  default     = "?OOMKilled ?\"Out of memory\" ?CrashLoopBackOff ?RunContainerError ?\"Back-off restarting failed container\" ?CreateContainerConfigError ?CreateContainerError ?ImagePullBackOff ?ErrImageNeverPull ?ErrImagePull ?InvalidImageName ?FailedScheduling ?\"Insufficient cpu\" ?\"Insufficient memory\" ?\"exceeded quota\" ?\"MountVolume.SetUp failed\" ?FailedMount ?FailedAttachVolume ?\"no space left on device\" ?Evicted ?DiskPressure ?MemoryPressure ?PIDPressure ?NodeNotReady ?FailedCreatePodSandBox ?NetworkNotReady ?\"Liveness probe failed\" ?\"Readiness probe failed\" ?\"panic:\""
}

variable "bedrock_model_id" {
  description = "Bedrock model id used by the ReAct agent (Amazon Nova Pro; supports Converse tool use)"
  type        = string
}

variable "lambda_source_dir" {
  description = "Path to the Lambda source directory"
  type        = string
}

variable "artifacts_bucket" {
  description = "S3 bucket used to publish the deps layer (avoids the 70MB direct PublishLayerVersion request limit)"
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda Python runtime"
  type        = string
  default     = "python3.12"
}

variable "enable_argocd_correlation" {
  description = "Enable best-effort ArgoCD deployment correlation"
  type        = bool
  default     = false
}

variable "argocd_server_url" {
  description = "ArgoCD server base URL for deployment correlation (e.g. https://argocd.example.com)"
  type        = string
  default     = ""
}

variable "max_agent_iterations" {
  description = "Max reason->act cycles for the LangGraph ReAct agent"
  type        = number
  default     = 6
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds (agent makes several round-trips)"
  type        = number
  default     = 300
}

variable "lambda_memory" {
  description = "Lambda memory in MB (LangChain import + agent loop)"
  type        = number
  default     = 1024
}

variable "eks_access_entry" {
  description = "Create an EKS access entry mapping the Lambda role to a read-only group"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
