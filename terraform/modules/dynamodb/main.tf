variable "project_name" {
  type    = string
}

variable "environment" {
  type    = string
}

resource "aws_dynamodb_table" "findings" {
  name         = "${var.project_name}-findings"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "finding_id"
  range_key    = "timestamp"

  attribute {
    name = "finding_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "severity"
    type = "S"
  }

  global_secondary_index {
    name            = "severity-index"
    hash_key        = "severity"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

output "table_name" {
  value = aws_dynamodb_table.findings.name
}

output "table_arn" {
  value = aws_dynamodb_table.findings.arn
}
