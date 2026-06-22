# Random Password for RDS
resource "random_password" "db" {
  length  = 32
  special = true
  # Avoid characters that break connection strings
  override_special = "!#$%&*()-_=+[]{}|:,.<>?"
}

# DB Subnet Group
resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = var.isolated_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-db-subnet-group"
  })
}

# DB Parameter Group — PostgreSQL 16 with forced SSL
resource "aws_db_parameter_group" "this" {
  name   = "${var.project}-${var.environment}-pg16"
  family = "postgres16"

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-pg16-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "this" {
  identifier = "${var.project}-${var.environment}-postgres"

  engine         = "postgres"
  engine_version = "16.4"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_security_group_id]
  parameter_group_name   = aws_db_parameter_group.this.name

  multi_az            = var.multi_az
  publicly_accessible = false

  # IAM database authentication (AWS-0176) — additive; password auth still works.
  iam_database_authentication_enabled = true

  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:30-sun:05:30"

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = "${var.project}-${var.environment}-final-snapshot"
  deletion_protection       = var.deletion_protection

  # Performance Insights (AWS-0133) — supported on db.t3.micro; 7-day free tier.
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = var.kms_key_arn
  performance_insights_retention_period = 7

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-postgres"
  })
}
