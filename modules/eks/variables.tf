variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the node group and control-plane ENIs"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs (control-plane ENIs / public load balancers)"
  type        = list(string)
}

variable "eks_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.large"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes (headroom for the Cluster Autoscaler)"
  type        = number
  default     = 6
}

variable "vpc_cni_version" {
  description = "Version of the vpc-cni addon (leave default for latest compatible)"
  type        = string
  default     = null
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint. Must not be 0.0.0.0/0 (AWS-0041)."
  type        = list(string)
  default     = ["27.111.74.12/32"]
}

variable "kms_key_arn" {
  description = "CMK ARN used for EKS secrets envelope encryption"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
