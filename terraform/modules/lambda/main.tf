variable "project_name" { type = string }
variable "environment"  { type = string }
variable "dynamodb_table_arn" { type = string }
variable "dynamodb_table_name" { type = string }
variable "alert_email" { type = string }
variable "dynamodb_stream_arn" { type = string }

# ---------- SNS Topic ----------
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ---------- IAM Role ----------
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:DescribeStream",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:ListStreams"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*",
          "${var.dynamodb_table_arn}/stream/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ---------- Package Lambda zips ----------
data "archive_file" "detector" {
  type        = "zip"
  source_file = "${path.root}/../lambda/detector/handler.py"
  output_path = "${path.root}/../lambda/detector/detector.zip"
}

data "archive_file" "responder" {
  type        = "zip"
  source_file = "${path.root}/../lambda/responder/handler.py"
  output_path = "${path.root}/../lambda/responder/responder.zip"
}

data "archive_file" "api" {
  type        = "zip"
  source_file = "${path.root}/../lambda/api/handler.py"
  output_path = "${path.root}/../lambda/api/api.zip"
}

# ---------- Lambda Functions ----------
resource "aws_lambda_function" "detector" {
  function_name    = "${var.project_name}-detector"
  filename         = data.archive_file.detector.output_path
  source_code_hash = data.archive_file.detector.output_base64sha256
  role             = aws_iam_role.lambda_exec.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }
}

resource "aws_lambda_function" "responder" {
  function_name    = "${var.project_name}-responder"
  filename         = data.archive_file.responder.output_path
  source_code_hash = data.archive_file.responder.output_base64sha256
  role             = aws_iam_role.lambda_exec.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
}

resource "aws_lambda_function" "api" {
  function_name    = "${var.project_name}-api"
  filename         = data.archive_file.api.output_path
  source_code_hash = data.archive_file.api.output_base64sha256
  role             = aws_iam_role.lambda_exec.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }
}

# ---------- DynamoDB Stream → Responder ----------
resource "aws_lambda_event_source_mapping" "dynamodb_stream" {
  event_source_arn  = var.dynamodb_stream_arn
  function_name     = aws_lambda_function.responder.arn
  starting_position = "LATEST"
}

# ---------- Outputs ----------
output "detector_arn" { value = aws_lambda_function.detector.arn }
output "api_arn"      { value = aws_lambda_function.api.arn }
output "sns_topic_arn" { value = aws_sns_topic.alerts.arn } 
output "api_lambda_name" { value = aws_lambda_function.api.function_name }
