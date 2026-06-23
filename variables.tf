variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name used for resource naming"
  type        = string
  default     = "infraguidai"
}

variable "environment" {
  description = "Environment name (prod, staging, dev)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "eks_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
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
  description = "Maximum number of worker nodes"
  type        = number
  default     = 6
}

variable "app_namespace" {
  description = "Kubernetes namespace the application pods run in"
  type        = string
  default     = "infraguid"
}

variable "ecr_namespace" {
  description = "ECR repository namespace prefix"
  type        = string
  default     = "infragui"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = false
}

variable "rds_db_name" {
  description = "RDS database name"
  type        = string
  default     = "infraguidai"
}

variable "rds_username" {
  description = "RDS master username"
  type        = string
  default     = "infraguidai_admin"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "nutritrack360.in"
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  type        = string
  default     = "Z02852643DE8LADNB6SIL"
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "901607650789"
}

variable "enable_cloudfront" {
  description = "Create the CloudFront distribution in front of the ALB. Enable only after the Gateway/ALB exists; the ALB origin is then auto-discovered by cluster tag."
  type        = bool
  default     = false
}

variable "alert_email" {
  description = "Admin email subscribed to the SNS alerts topic"
  type        = string
  default     = ""
}

variable "bedrock_logintel_model_id" {
  description = "Bedrock model id used by the log-intel Lambda's ReAct agent (Amazon Nova Pro; supports Converse tool use)"
  type        = string
  default     = "amazon.nova-pro-v1:0"
}

variable "enable_argocd_correlation" {
  description = "Enable best-effort ArgoCD deployment correlation in the log-intel Lambda"
  type        = bool
  default     = false
}

variable "enable_log_intel" {
  description = "Deploy the CS-02 Log Intelligence Lambda (langchain deps layer). Disabled by default — the layer exceeds Lambda's 70MB direct-upload limit; needs S3-based layer publishing before enabling."
  type        = bool
  default     = false
}

variable "argocd_server_url" {
  description = "ArgoCD server base URL used by the log-intel agent for deployment correlation"
  type        = string
  default     = ""
}

variable "dr_region" {
  description = "AWS region for DR resources (S3 replica buckets, RDS backup replication)"
  type        = string
  default     = "ap-south-1"
}

variable "enable_s3_replication" {
  description = "Enable cross-region S3 replication from primary to dr_region"
  type        = bool
  default     = false
}

variable "rds_backup_retention_period" {
  description = "Days to retain RDS automated backups (must be >=1 to enable backup replication)"
  type        = number
  default     = 7
}

variable "enable_rds_backup_replication" {
  description = "Replicate RDS automated backups to dr_region. Requires rds_backup_retention_period >= 1."
  type        = bool
  default     = false
}

variable "rds_deletion_protection" {
  description = "Enable RDS deletion protection (AWS-0177). Secure-by-default; set false only for teardown."
  type        = bool
  default     = true
}

variable "eks_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint. Default is the admin IP; must not be 0.0.0.0/0 (AWS-0041)."
  type        = list(string)
  default     = ["27.111.74.12/32"]
}
