variable "project_name"  { type = string }
variable "environment"   { type = string }
variable "detector_arn"  { type = string }

# ---------- Permission for EventBridge to invoke Lambda ----------
resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.detector_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudtrail_events.arn
}

# ---------- EventBridge rule ----------
resource "aws_cloudwatch_event_rule" "cloudtrail_events" {
  name        = "${var.project_name}-cloudtrail-rule"
  description = "Capture suspicious CloudTrail events for CloudGuard"

  event_pattern = jsonencode({
    source      = ["aws.iam", "aws.s3", "aws.cloudtrail"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        "DeleteBucket",
        "PutBucketAcl",
        "PutBucketPolicy",
        "DeleteBucketPolicy",
        "CreateUser",
        "DeleteUser",
        "AttachUserPolicy",
        "DetachUserPolicy",
        "CreateAccessKey",
        "DeleteAccessKey",
        "ConsoleLogin",
        "StopLogging",
        "DeleteTrail",
        "PutEventSelectors"
      ]
    }
  })
}

# ---------- EventBridge target → detector Lambda ----------
resource "aws_cloudwatch_event_target" "detector" {
  rule      = aws_cloudwatch_event_rule.cloudtrail_events.name
  target_id = "CloudGuardDetector"
  arn       = var.detector_arn
}

output "rule_arn" { value = aws_cloudwatch_event_rule.cloudtrail_events.arn }
