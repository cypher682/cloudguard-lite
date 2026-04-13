import json
import boto3
import os

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["DYNAMODB_TABLE"])

def lambda_handler(event, context):
    query_params = event.get("queryStringParameters") or {}
    severity_filter = query_params.get("severity")

    try:
        if severity_filter:
            response = table.query(
                IndexName="severity-index",
                KeyConditionExpression=boto3.dynamodb.conditions.Key("severity").eq(severity_filter)
            )
        else:
            response = table.scan(Limit=50)

        findings = response.get("Items", [])

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({
                "count":    len(findings),
                "findings": findings
            })
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
