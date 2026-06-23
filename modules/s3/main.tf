terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.dr]
    }
  }
}

locals {
  buckets = {
    documents        = "${var.project}-${var.environment}-documents-${var.aws_account_id}"
    knowledge_base   = "${var.project}-${var.environment}-knowledge-base-${var.aws_account_id}"
    lambda_artifacts = "${var.project}-${var.environment}-lambda-artifacts-${var.aws_account_id}"
  }

  replica_buckets = var.enable_replication ? {
    documents        = "${var.project}-${var.environment}-documents-${var.aws_account_id}-replica"
    knowledge_base   = "${var.project}-${var.environment}-knowledge-base-${var.aws_account_id}-replica"
    lambda_artifacts = "${var.project}-${var.environment}-lambda-artifacts-${var.aws_account_id}-replica"
  } : {}
}

resource "aws_s3_bucket" "this" {
  for_each = local.buckets

  bucket = each.value

  tags = merge(var.tags, {
    Name = each.value
  })
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = aws_s3_bucket.this
  bucket   = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = aws_s3_bucket.this
  bucket   = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = aws_s3_bucket.this
  bucket   = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "replication" {
  count = var.enable_replication ? 1 : 0
  name  = "${var.project}-${var.environment}-s3-replication"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "replication" {
  count = var.enable_replication ? 1 : 0
  name  = "${var.project}-${var.environment}-s3-replication-policy"
  role  = aws_iam_role.replication[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "SourceBuckets"
        Effect   = "Allow"
        Action   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
        Resource = [for b in aws_s3_bucket.this : b.arn]
      },
      {
        Sid    = "SourceObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = [for b in aws_s3_bucket.this : "${b.arn}/*"]
      },
      {
        Sid      = "DestObjects"
        Effect   = "Allow"
        Action   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
        Resource = [for b in aws_s3_bucket.replica : "${b.arn}/*"]
      },
      {
        Sid      = "SourceKMSDecrypt"
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = [var.kms_key_arn]
      },
      {
        Sid      = "DestKMSEncrypt"
        Effect   = "Allow"
        Action   = ["kms:Encrypt", "kms:GenerateDataKey"]
        Resource = [var.dr_kms_key_arn]
      }
    ]
  })
}

resource "aws_s3_bucket" "replica" {
  for_each = local.replica_buckets
  provider = aws.dr

  bucket = each.value

  tags = merge(var.tags, {
    Name = each.value
    Role = "replica"
  })
}

resource "aws_s3_bucket_versioning" "replica" {
  for_each = aws_s3_bucket.replica
  provider = aws.dr
  bucket   = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  for_each = aws_s3_bucket.replica
  provider = aws.dr
  bucket   = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.dr_kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "replica" {
  for_each = aws_s3_bucket.replica
  provider = aws.dr
  bucket   = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.project}-${var.environment}-access-logs-${var.aws_account_id}"

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-access-logs"
    Role = "access-logs"
  })
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket                  = aws_s3_bucket.access_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "S3ServerAccessLogsPolicy"
      Effect    = "Allow"
      Principal = { Service = "logging.s3.amazonaws.com" }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.access_logs.arn}/*"
      Condition = {
        StringEquals = { "aws:SourceAccount" = var.aws_account_id }
        ArnLike      = { "aws:SourceArn" = [for b in aws_s3_bucket.this : b.arn] }
      }
    }]
  })
}

resource "aws_s3_bucket_logging" "this" {
  for_each = aws_s3_bucket.this

  bucket        = each.value.id
  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "s3-access/${each.key}/"
}

resource "aws_s3_bucket_replication_configuration" "this" {
  for_each = var.enable_replication ? aws_s3_bucket.this : {}

  bucket     = each.value.id
  role       = aws_iam_role.replication[0].arn
  depends_on = [aws_s3_bucket_versioning.this]

  rule {
    id     = "replicate-all-to-dr"
    status = "Enabled"

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = aws_s3_bucket.replica[each.key].arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = var.dr_kms_key_arn
      }
    }
  }
}
