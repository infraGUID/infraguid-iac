# One ECR repository per containerized service.
# Repo names are namespaced as "infragui/<service>" per project convention.
resource "aws_ecr_repository" "this" {
  for_each = toset(var.repositories)

  name = "${var.namespace}/${each.value}"
  # Immutable tags (AWS-0031) — the CD pipeline publishes unique semver tags and
  # blocks re-publishing an existing tag, so immutability is compatible.
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = merge(var.tags, {
    Name = "${var.namespace}/${each.value}"
  })
}

# Lifecycle policy — keep the last 10 tagged images, expire untagged after 7 days.
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["main", "v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      }
    ]
  })
}
