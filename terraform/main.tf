module "dynamodb" {
  source       = "./modules/dynamodb"
  project_name = var.project_name
  environment  = var.environment
}

module "lambda" {
  source              = "./modules/lambda"
  project_name        = var.project_name
  environment         = var.environment
  alert_email         = var.alert_email
  dynamodb_table_arn  = module.dynamodb.table_arn
  dynamodb_table_name = module.dynamodb.table_name
  dynamodb_stream_arn = module.dynamodb.stream_arn
}

module "cloudtrail" {
  source       = "./modules/cloudtrail"
  project_name = var.project_name
  environment  = var.environment
}

module "eventbridge" {
  source       = "./modules/eventbridge"
  project_name = var.project_name
  environment  = var.environment
  detector_arn = module.lambda.detector_arn
}
