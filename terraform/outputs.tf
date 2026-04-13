output "dynamodb_table_name" { value = module.dynamodb.table_name }
output "dynamodb_table_arn"  { value = module.dynamodb.table_arn }
output "detector_arn"        { value = module.lambda.detector_arn }
output "api_arn"             { value = module.lambda.api_arn }
output "sns_topic_arn"       { value = module.lambda.sns_topic_arn }
output "cloudtrail_arn"      { value = module.cloudtrail.cloudtrail_arn }
output "eventbridge_rule_arn" { value = module.eventbridge.rule_arn }
output "api_url" { value = module.api_gateway.api_url }
