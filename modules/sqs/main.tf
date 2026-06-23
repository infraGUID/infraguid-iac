resource "aws_sqs_queue" "ingestion_dlq" {
  name                      = "${var.project}-${var.environment}-ingestion-dlq"
  message_retention_seconds = var.dlq_retention_seconds
  kms_master_key_id         = var.kms_key_arn

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-ingestion-dlq"
  })
}

resource "aws_sqs_queue" "ingestion" {
  name                       = "${var.project}-${var.environment}-ingestion"
  message_retention_seconds  = var.message_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
  receive_wait_time_seconds = var.receive_wait_time_seconds
  kms_master_key_id         = var.kms_key_arn

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.ingestion_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-ingestion"
  })
}

resource "aws_sqs_queue_redrive_allow_policy" "ingestion_dlq" {
  queue_url = aws_sqs_queue.ingestion_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.ingestion.arn]
  })
}
