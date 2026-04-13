variable "project_name" { type = string }
variable "environment"  { type = string }
variable "api_arn"      { type = string }
variable "api_lambda_name" { type = string }

# ---------- REST API ----------
resource "aws_api_gateway_rest_api" "cloudguard" {
  name        = "${var.project_name}-api"
  description = "CloudGuard Lite findings API"
}

# ---------- /findings resource ----------
resource "aws_api_gateway_resource" "findings" {
  rest_api_id = aws_api_gateway_rest_api.cloudguard.id
  parent_id   = aws_api_gateway_rest_api.cloudguard.root_resource_id
  path_part   = "findings"
}

# ---------- GET method ----------
resource "aws_api_gateway_method" "get_findings" {
  rest_api_id   = aws_api_gateway_rest_api.cloudguard.id
  resource_id   = aws_api_gateway_resource.findings.id
  http_method   = "GET"
  authorization = "NONE"
}

# ---------- Lambda integration ----------
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.cloudguard.id
  resource_id             = aws_api_gateway_resource.findings.id
  http_method             = aws_api_gateway_method.get_findings.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${var.api_arn}/invocations"
}

# ---------- Deployment ----------
resource "aws_api_gateway_deployment" "cloudguard" {
  rest_api_id = aws_api_gateway_rest_api.cloudguard.id

  depends_on = [
    aws_api_gateway_integration.lambda
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# ---------- Stage ----------
resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.cloudguard.id
  rest_api_id   = aws_api_gateway_rest_api.cloudguard.id
  stage_name    = var.environment
}

# ---------- Permission for API Gateway to invoke Lambda ----------
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.api_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.cloudguard.execution_arn}/*/*"
}

# ---------- Outputs ----------
output "api_url" {
  value = "${aws_api_gateway_stage.dev.invoke_url}/findings"
}
