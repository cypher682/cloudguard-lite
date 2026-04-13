import json
import boto3
import uuid
import os
from datetime import datetime, timezone

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["DYNAMODB_TABLE"])

SUSPICIOUS_EVENTS = {
    "DeleteBucket":              "HIGH",
    "PutBucketAcl":              "HIGH",
    "PutBucketPolicy":           "MEDIUM",
    "DeleteBucketPolicy":        "MEDIUM",
    "CreateUser":                "MEDIUM",
    "DeleteUser":                "HIGH",
    "AttachUserPolicy":          "HIGH",
    "DetachUserPolicy":          "MEDIUM",
    "CreateAccessKey":           "HIGH",
    "DeleteAccessKey":           "MEDIUM",
    "ConsoleLogin":              "LOW",
    "StopLogging":               "CRITICAL",
    "DeleteTrail":               "CRITICAL",
    "PutEventSelectors":         "HIGH",
}

def lambda_handler(event, context):
    detail = event.get("detail", {})
    event_name = detail.get("eventName", "")
    severity = SUSPICIOUS_EVENTS.get(event_name)

    if not severity:
        return {"statusCode": 200, "body": "Event not monitored"}

    finding = {
        "finding_id":   str(uuid.uuid4()),
        "timestamp":    datetime.now(timezone.utc).isoformat(),
        "event_name":   event_name,
        "severity":     severity,
        "source_ip":    detail.get("sourceIPAddress", "unknown"),
        "user_agent":   detail.get("userAgent", "unknown"),
        "user_identity": json.dumps(detail.get("userIdentity", {})),
        "region":       detail.get("awsRegion", "unknown"),
        "raw_event":    json.dumps(detail),
    }

    table.put_item(Item=finding)
    print(f"Finding logged: {event_name} | Severity: {severity} | ID: {finding['finding_id']}")

    return {"statusCode": 200, "body": json.dumps(finding)}

