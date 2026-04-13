import json
import boto3
import os

sns = boto3.client("sns")
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

def lambda_handler(event, context):
    for record in event.get("Records", []):
        if record["eventName"] != "INSERT":
            continue

        new_image = record["dynamodb"].get("NewImage", {})

        finding_id = new_image.get("finding_id", {}).get("S", "unknown")
        event_name = new_image.get("event_name", {}).get("S", "unknown")
        severity   = new_image.get("severity",   {}).get("S", "unknown")
        source_ip  = new_image.get("source_ip",  {}).get("S", "unknown")
        timestamp  = new_image.get("timestamp",  {}).get("S", "unknown")
        region     = new_image.get("region",     {}).get("S", "unknown")

        subject = f"[CloudGuard] {severity} Alert — {event_name}"

        message = f"""
CloudGuard Lite Security Finding
=================================
Finding ID : {finding_id}
Event      : {event_name}
Severity   : {severity}
Source IP  : {source_ip}
Region     : {region}
Time       : {timestamp}

Review your AWS account immediately if this activity was not expected.
        """.strip()

        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )

        print(f"Alert sent for finding: {finding_id} | {severity} | {event_name}")

    return {"statusCode": 200}
