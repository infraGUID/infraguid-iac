# Cognito User Pool
resource "aws_cognito_user_pool" "this" {
  name = "${var.project}-${var.environment}-users"

  # Username is email
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Password policy
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  # Schema attributes
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    name                = "name"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    name                = "role"
    attribute_data_type = "String"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 50
    }
  }

  # Email verification
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "InfraGuidAI — Verify your email"
    email_message        = "Your verification code is {####}"
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-user-pool"
  })
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "this" {
  name         = "${var.project}-${var.environment}-web-client"
  user_pool_id = aws_cognito_user_pool.this.id

  # No client secret — frontend is a public JS app
  generate_secret = false

  # Auth flows matching frontend auth.js (USER_PASSWORD_AUTH)
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  # Token validity
  access_token_validity  = 1  # hours
  id_token_validity      = 1  # hours
  refresh_token_validity = 30 # days

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # custom:role is readable (so the app can read the role claim) but NOT
  # client-writable: this prevents users from self-assigning admin at signup.
  # Admins are promoted out-of-band via admin-update-user-attributes.
  read_attributes  = ["email", "name", "custom:role"]
  write_attributes = ["email", "name"]

  prevent_user_existence_errors = "ENABLED"
}

# Admin Group
resource "aws_cognito_user_group" "admin" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.this.id
  description  = "Admin users with access to the admin panel"
}
