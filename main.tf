# Terraform Configuration
terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "infraguidai-tfstate-901607650789"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "infraguidai-tfstate-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region

  default_tags {
    tags = local.common_tags
  }
}

# Local Values
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Containerized services that get an ECR repository.
  ecr_services = [
    "chat-service",
    "agent-service",
    "rag-service",
    "ingestion-service",
    "frontend",
  ]

  # ── Cost Estimation ────────────────────────────────────────────────────────
  # On-demand pricing for us-east-1. For accurate CI cost gating use Infracost:
  #   infracost breakdown --path .
  hours_per_month = 730 # 365 * 24 / 12

  # EKS — control plane + worker nodes (t3.large)
  _eks_control_plane = 0.10 * local.hours_per_month
  _eks_workers       = 0.0832 * local.hours_per_month * var.node_desired_size
  cost_eks           = local._eks_control_plane + local._eks_workers

  # RDS — db.t3.micro instance + gp2 storage (doubles for Multi-AZ)
  _rds_instance = 0.017 * local.hours_per_month * (var.rds_multi_az ? 2 : 1)
  _rds_storage  = 0.115 * var.rds_allocated_storage
  cost_rds      = local._rds_instance + local._rds_storage

  # NAT Gateways — one per AZ + estimated data processing
  _nat_hourly = 0.045 * local.hours_per_month * length(var.azs)
  _nat_data   = 10.0 # $/month data processing estimate
  cost_nat    = local._nat_hourly + local._nat_data

  # ALB — base hourly only (provisioned by ALB Ingress Controller, not Terraform)
  cost_alb = 0.008 * local.hours_per_month

  # ECR — 5 repositories, estimated 10 GB total image storage
  cost_ecr = 0.10 * 10.0

  # S3 — 3 buckets (documents, knowledge-base, lambda-artifacts), ~20 GB est.
  cost_s3 = 0.023 * 20.0

  # KMS — $1/key/month for the single customer-managed key
  cost_kms = 1.00

  # Secrets Manager — $0.40/secret/month
  cost_secrets = 0.40

  # Route53 — $0.50/hosted zone/month
  cost_route53 = 0.50

  # Lambda, SQS, SNS, Cognito — within AWS free tier at capstone scale
  cost_free_tier_services = 0.0

  # ── Totals ─────────────────────────────────────────────────────────────────
  cost_total_monthly = (
    local.cost_eks +
    local.cost_rds +
    local.cost_nat +
    local.cost_alb +
    local.cost_ecr +
    local.cost_s3 +
    local.cost_kms +
    local.cost_secrets +
    local.cost_route53 +
    local.cost_free_tier_services
  )

  # Terraform has no round(); floor(x + 0.5) rounds to the nearest integer.
  cost_breakdown = {
    eks_control_plane        = floor(local._eks_control_plane + 0.5)
    eks_worker_nodes         = floor(local._eks_workers + 0.5)
    rds_instance_and_storage = floor(local.cost_rds + 0.5)
    nat_gateways             = floor(local.cost_nat + 0.5)
    alb_base                 = floor(local.cost_alb + 0.5)
    ecr_storage              = floor(local.cost_ecr + 0.5)
    s3_storage               = floor(local.cost_s3 + 0.5)
    kms                      = floor(local.cost_kms + 0.5)
    secrets_manager          = floor(local.cost_secrets + 0.5)
    route53                  = floor(local.cost_route53 + 0.5)
    lambda_sqs_sns_cognito   = 0
    total_estimated          = floor(local.cost_total_monthly + 0.5)
  }
}

# ─────────────────────────────── Networking ───────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  project     = var.project
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  azs         = var.azs
  aws_region  = var.aws_region
  kms_key_arn = module.kms.key_arn
  tags        = local.common_tags
}

# ─────────────────────────────── Encryption ───────────────────────────────
module "kms" {
  source = "./modules/kms"

  project        = var.project
  environment    = var.environment
  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region
  tags           = local.common_tags
}

module "kms_dr" {
  source = "./modules/kms"

  providers = {
    aws = aws.dr
  }

  project        = var.project
  environment    = var.environment
  aws_account_id = var.aws_account_id
  aws_region     = var.dr_region
  tags           = local.common_tags
}

# ─────────────────────────────── Storage (new buckets) ─────────────────────
module "s3" {
  source = "./modules/s3"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  project            = var.project
  environment        = var.environment
  aws_account_id     = var.aws_account_id
  kms_key_arn        = module.kms.key_arn
  aws_region         = var.aws_region
  dr_region          = var.dr_region
  enable_replication = var.enable_s3_replication
  dr_kms_key_arn     = module.kms_dr.key_arn
  tags               = local.common_tags
}

# ─────────────────────────────── Auth ──────────────────────────────────────
module "cognito" {
  source = "./modules/cognito"

  project     = var.project
  environment = var.environment
  tags        = local.common_tags
}

# ─────────────────────────────── Database ─────────────────────────────────
module "rds" {
  source = "./modules/rds"

  project                 = var.project
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  isolated_subnet_ids     = module.vpc.isolated_subnet_ids
  rds_security_group_id   = module.vpc.rds_security_group_id
  kms_key_arn             = module.kms.key_arn
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  multi_az                = var.rds_multi_az
  db_name                 = var.rds_db_name
  db_username             = var.rds_username
  backup_retention_period = var.rds_backup_retention_period
  skip_final_snapshot     = !var.enable_rds_backup_replication
  deletion_protection     = var.rds_deletion_protection
  tags                    = local.common_tags
}

resource "aws_db_instance_automated_backups_replication" "this" {
  count = var.enable_rds_backup_replication ? 1 : 0

  provider = aws.dr

  source_db_instance_arn = module.rds.db_instance_arn
  kms_key_id             = module.kms_dr.key_arn

  depends_on = [module.kms_dr]
}

# ─────────────────────────────── Async queue ──────────────────────────────
module "sqs" {
  source = "./modules/sqs"

  project     = var.project
  environment = var.environment
  kms_key_arn = module.kms.key_arn
  tags        = local.common_tags
}

# ─────────────────────────────── Secrets ─────────────────────────────────
module "secrets" {
  source = "./modules/secrets"

  project                 = var.project
  environment             = var.environment
  kms_key_arn             = module.kms.key_arn
  rds_endpoint            = module.rds.endpoint
  rds_username            = module.rds.username
  rds_password            = module.rds.password
  rds_db_name             = module.rds.db_name
  cognito_user_pool_id    = module.cognito.user_pool_id
  cognito_app_client_id   = module.cognito.app_client_id
  s3_document_bucket      = module.s3.documents_bucket_name
  sqs_ingestion_queue_url = module.sqs.ingestion_queue_url
  aws_region              = var.aws_region
  tags                    = local.common_tags
}

# ─────────────────────────────── ECR ──────────────────────────────────────
module "ecr" {
  source = "./modules/ecr"

  namespace    = var.ecr_namespace
  repositories = local.ecr_services
  kms_key_arn  = module.kms.key_arn
  tags         = local.common_tags
}

# ─────────────────────────────── EKS ──────────────────────────────────────
module "eks" {
  source = "./modules/eks"

  project             = var.project
  environment         = var.environment
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  eks_version         = var.eks_version
  node_instance_type  = var.node_instance_type
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  public_access_cidrs = var.eks_public_access_cidrs
  kms_key_arn         = module.kms.key_arn
  tags                = local.common_tags
}

# Allow worker nodes to reach RDS.
resource "aws_vpc_security_group_ingress_rule" "rds_from_nodes" {
  security_group_id            = module.vpc.rds_security_group_id
  description                  = "PostgreSQL from EKS worker nodes"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = module.eks.cluster_security_group_id
}

# ─────────────────────────────── IRSA ─────────────────────────────────────
module "irsa" {
  source = "./modules/irsa"

  project                   = var.project
  environment               = var.environment
  oidc_provider_arn         = module.eks.oidc_provider_arn
  oidc_provider_url         = module.eks.oidc_provider_url
  cluster_name              = module.eks.cluster_name
  app_namespace             = var.app_namespace
  kms_key_arn               = module.kms.key_arn
  secret_arn                = module.secrets.secret_arn
  documents_bucket_arn      = module.s3.documents_bucket_arn
  knowledge_base_bucket_arn = module.s3.knowledge_base_bucket_arn
  ingestion_queue_arns      = [module.sqs.ingestion_queue_arn, module.sqs.ingestion_dlq_arn]
  tags                      = local.common_tags
}

# EBS CSI driver addon — separate from module.eks to avoid a circular
# dependency (the addon needs the IRSA role ARN from module.irsa, which itself
# depends on module.eks for the OIDC provider ARN).
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = module.irsa.ebs_csi_role_arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = local.common_tags
}

# ─────────────────────────── DNS / Certificate ────────────────────────────
module "dns" {
  source = "./modules/dns"

  domain_name    = var.domain_name
  hosted_zone_id = var.hosted_zone_id
  tags           = local.common_tags
}

# ─────────────────────── Frontend CDN (CloudFront) ────────────────────────
# CloudFront caches the pod-served frontend at the edge, using the Gateway ALB
# as origin. Two-phase: apply once with enable_cloudfront=false to stand up the
# cluster + Gateway, then set enable_cloudfront=true and apply again — the ALB
# origin is auto-discovered by cluster tag. The CloudFront workflow
# (.github/workflows/cloudfront.yml) automates this. See modules/frontend.
module "frontend" {
  source = "./modules/frontend"
  count  = var.enable_cloudfront ? 1 : 0

  project             = var.project
  environment         = var.environment
  domain_name         = var.domain_name
  hosted_zone_id      = var.hosted_zone_id
  acm_certificate_arn = module.dns.acm_certificate_validated_arn
  eks_cluster_name    = module.eks.cluster_name
  vpc_id              = module.vpc.vpc_id
  tags                = local.common_tags
}

# ─────────────────────────────── SNS alerts ───────────────────────────────
module "sns" {
  source = "./modules/sns"

  project     = var.project
  environment = var.environment
  alert_email = var.alert_email
  kms_key_id  = module.kms.key_arn
  tags        = local.common_tags
}

# ──────────────────── CloudWatch autoscaling alarms ───────────────────────
# Alerts when the EKS node group hits its max size (cluster autoscaler can't
# add nodes) or runs sustained-high CPU. Publishes to a dedicated, properly
# permissioned SNS topic (see modules/cloudwatch for why it isn't the log-intel
# alerts topic) that emails var.alert_email.
module "cloudwatch" {
  source = "./modules/cloudwatch"

  project             = var.project
  environment         = var.environment
  aws_region          = var.aws_region
  aws_account_id      = var.aws_account_id
  alert_email         = var.alert_email
  node_group_asg_name = module.eks.node_group_asg_name
  node_max_size       = var.node_max_size
  tags                = local.common_tags
}

# ─────────────────── CS-02 Log Intelligence Agent (Lambda) ────────────────
module "log_intel_lambda" {
  source = "./modules/log-intel-lambda"
  count  = var.enable_log_intel ? 1 : 0

  project                   = var.project
  environment               = var.environment
  aws_region                = var.aws_region
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  sns_topic_arn             = module.sns.topic_arn
  secret_arn                = module.secrets.secret_arn
  kms_key_arn               = module.kms.key_arn
  eks_cluster_name          = module.eks.cluster_name
  bedrock_model_id          = var.bedrock_logintel_model_id
  lambda_source_dir         = "${path.root}/../infraguid-microservices/services/log-intel-lambda"
  artifacts_bucket          = module.s3.lambda_artifacts_bucket_name
  enable_argocd_correlation = var.enable_argocd_correlation
  argocd_server_url         = var.argocd_server_url
  tags                      = local.common_tags
}

# One-time adoption of the pre-existing pod-logs CloudWatch log group. After a
# CI apply destroyed the log-intel module, the group was recreated out-of-band
# so Fluent Bit could keep shipping; a plain re-enable apply would otherwise
# fail with "log group already exists". This import block makes the apply ADOPT
# it. Safe to remove in a follow-up once the first apply has imported it.
import {
  to = module.log_intel_lambda[0].aws_cloudwatch_log_group.pod_logs
  id = "/infraguid/prod/pod-logs"
}

# Allow the log-intel Lambda to reach the EKS API server (private endpoint).
# Without this the Lambda's read-only k8s tool calls (pod status, events, nodes)
# time out, and the agent can only report from logs/metrics. RBAC access is
# granted separately via the module's EKS access entry (log-intel-readers).
resource "aws_vpc_security_group_ingress_rule" "eks_api_from_log_intel" {
  count                        = var.enable_log_intel ? 1 : 0
  security_group_id            = module.eks.cluster_security_group_id
  description                  = "HTTPS from log-intel Lambda to EKS API server"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = module.log_intel_lambda[0].security_group_id
}
