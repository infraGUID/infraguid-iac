# Secrets Manager Secret
resource "aws_secretsmanager_secret" "app" {
  name        = "${var.project}/${var.environment}/app-secrets"
  description = "Application secrets for ${var.project} ${var.environment}"
  kms_key_id  = var.kms_key_arn

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-app-secrets"
  })
}

# Secret Version — populated with all runtime config
locals {
  # Strip the port from the endpoint if present (RDS returns host:port)
  rds_host = split(":", var.rds_endpoint)[0]
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id

  secret_string = jsonencode({
    POSTGRES_URI               = "postgresql+asyncpg://${var.rds_username}:${urlencode(var.rds_password)}@${local.rds_host}:5432/${var.rds_db_name}"
    COGNITO_USER_POOL_ID       = var.cognito_user_pool_id
    COGNITO_APP_CLIENT_ID      = var.cognito_app_client_id
    S3_DOCUMENT_BUCKET         = var.s3_document_bucket
    SQS_INGESTION_QUEUE_URL    = var.sqs_ingestion_queue_url
    BEDROCK_CHAT_MODEL_ID      = "amazon.nova-pro-v1:0"
    BEDROCK_EMBEDDING_MODEL_ID = "amazon.titan-embed-text-v2:0"
  })
}
