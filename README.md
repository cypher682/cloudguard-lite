# CloudGuard Lite

A serverless AWS security monitoring system that detects suspicious IAM and S3 activity in real time.

---

## Architecture

```
CloudTrail → EventBridge → detector Lambda → DynamoDB
                                      ↓
                              DynamoDB Stream
                                      ↓
                         responder Lambda → SNS Email

API Gateway → api Lambda → DynamoDB
```

---

## What it detects

| Event               | Severity |
|--------------------|----------|
| DeleteBucket       | HIGH     |
| PutBucketAcl       | HIGH     |
| CreateAccessKey    | HIGH     |
| AttachUserPolicy   | HIGH     |
| DeleteUser         | HIGH     |
| StopLogging        | CRITICAL |
| DeleteTrail        | CRITICAL |
| PutBucketPolicy    | MEDIUM   |
| CreateUser         | MEDIUM   |
| ConsoleLogin       | LOW      |

---

## Stack

- **Compute** — AWS Lambda (Python 3.12)  
- **Eventing** — EventBridge + CloudTrail  
- **Storage** — DynamoDB with Streams  
- **Alerting** — SNS  
- **API** — API Gateway (REST)  
- **IaC** — Terraform  
- **CI/CD** — GitHub Actions (Day 5)

---

## Endpoints

| Method | Path                    | Description                 |
|--------|-------------------------|-----------------------------|
| GET    | /findings              | Retrieve last 50 findings   |
| GET    | /findings?severity=HIGH | Filter findings by severity |

---

## Setup

```bash
cd terraform
terraform init
terraform apply -var="alert_email=your@email.com"
```

---

## Local Test

```bash
aws iam create-access-key --user-name <any-user>

# Wait 30–60 seconds

curl "https://<api-url>/dev/findings?severity=HIGH"
```

---

## Notes

- Ensure CloudTrail is enabled and logging management events.
- Detection latency is typically a few seconds.
- Confirm SNS email subscription to receive alerts.
