output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  value = module.dynamodb.table_arn
}

output "detector_arn"        { value = module.lambda.detector_arn }
output "api_arn"             { value = module.lambda.api_arn }
output "sns_topic_arn"       { value = module.lambda.sns_topic_arn }
