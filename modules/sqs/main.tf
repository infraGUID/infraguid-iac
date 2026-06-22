# SQS queue for asynchronous knowledge-base ingestion.
#
# The ingestion-service `/ingest` endpoint enqueues a job here and returns
# immediately; the service's background worker drains the queue and runs the
# slow (Bedrock-throttled) embedding/upsert out of band. Failed jobs are
# redelivered after the visibility timeout and, after `max_receive_count`
# attempts, moved to the dead-letter queue for inspection.

# ─────────────────────────── Dead-letter queue ────────────────────────────
resource "aws_sqs_queue" "ingestion_dlq" {
  name                      = "${var.project}-${var.environment}-ingestion-dlq"
  message_retention_seconds = var.dlq_retention_seconds
  kms_master_key_id         = var.kms_key_arn

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-ingestion-dlq"
  })
}

# ─────────────────────────────── Main queue ───────────────────────────────
resource "aws_sqs_queue" "ingestion" {
  name                       = "${var.project}-${var.environment}-ingestion"
  message_retention_seconds  = var.message_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
  # Long polling: consumers wait up to 20s for a message, cutting empty receives.
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

# Tie the DLQ to its source queue (so only this queue can redrive into it).
resource "aws_sqs_queue_redrive_allow_policy" "ingestion_dlq" {
  queue_url = aws_sqs_queue.ingestion_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.ingestion.arn]
  })
}
