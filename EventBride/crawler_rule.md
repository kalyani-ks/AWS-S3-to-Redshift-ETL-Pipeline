## crawler_rule

These rules are designed for crawlers to handle crawler state changes, which are published in an SNS topic.

**crawler01_rule**
```json
{
  "source": ["aws.glue"],
  "detail-type": ["Glue Crawler State Change"],
  "detail": {
    "state": ["Succeeded", "Failed"],
    "crawlerName": ["csv_data_read"]
  }
}
```
**IAM role for crwaler01_rule**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sns:Publish"
            ],
            "Resource": [
                "arn:aws:sns:ap-south-1:183295412439:OrderNotifiction"
            ]
        }
    ]
}
```

Trust Relationship
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "events.amazonaws.com"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                
                "StringsEquals": {
                    "aws:SourceAccount": "183295412439"
                },
                "ArnEquals": {
                    "aws:SourceArn": "arn:aws:events:ap-south-1:183295412439:rule/crawler01_rule"
                }

           }
        }
    ]
}
```

### Crawler02_rule
**Event Pattern**
```json
{
  "source": ["aws.glue"],
  "detail-type": ["Glue Crawler State Change"],
  "detail": {
    "state": ["Succeeded", "Failed"],
    "crawlerName": ["parquet_data_reader"]
  }
}
```
**IAM role for crwaler02_rule**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sns:Publish"
            ],
            "Resource": [
                "arn:aws:sns:ap-south-1:183295412439:OrderNotifiction"
            ]
        }
    ]
}
```

Trust relationship

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "events.amazonaws.com"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                
                "StringsEquals": {
                    "aws:SourceAccount": "183295412439"
                },
                "ArnEquals": {
                    "aws:SourceArn": "arn:aws:events:ap-south-1:183295412439:rule/crawler02_rule"
                }

           }
        }
    ]
}
```
