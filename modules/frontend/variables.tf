variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Public domain served by CloudFront (also the Host the ALB HTTPRoute matches)"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for the apex alias records"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for the CloudFront viewer cert (must be in us-east-1)"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name, used to auto-discover the Gateway-provisioned ALB (origin) by its elbv2.k8s.aws/cluster tag"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB lives; used to create the CloudFront-only security group"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
