## crawler-rule

These rules are designed for crawlers to handle crawler state changes, which are published in an SNS topic.

**crawler-01-rule**
```json
{
  "source": ["aws.glue"],
  "detail-type": ["Glue Crawler State Change"],
  "detail": {
    "state": ["Succeeded", "Failed"],
    "crawlerName": ["csv_data_reader"]
  }
}
```
**IAM role for crwaler-01-rule**
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
                "arn:aws:sns:ap-south-1:183295412439:sales-data-topic"
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
                    "aws:SourceArn": "arn:aws:events:ap-south-1:183295412439:rule/crawler-01-rule"
                }

           }
        }
    ]
}
```

### Crawler-02-rule
**Event Pattern**
```json
{
  "source": ["aws.glue"],
  "detail-type": ["Glue Crawler State Change"],
  "detail": {
    "state": ["Succeeded", "Failed"],
    "crawlerName": ["parquet-data-reader"]
  }
}
```
**IAM role for crwaler-02-rule**
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
                "arn:aws:sns:ap-south-1:183295412439:sales-data-topic"
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
                    "aws:SourceArn": "arn:aws:events:ap-south-1:183295412439:rule/crawler-02-rule"
                }

           }
        }
    ]
}
```

* While  creating both rules select input transformer in  the target input.
* Configure  `input transformer` with the following:
  **Input path**
```json
{
  "Message": "$.detail.message",
  "compeletion": "$.detail.completionDate",
  "crawlerName": "$.detail.crawlerName",
  "status": "$.detail.state",
  "warningMessage": "$.detail.warningMessage"
}
```
**Template**
```json
{
  "Crawler Notification":
  {
    "Crawler-Name":"<crawlerName>",
    "Status":"<status>",
    "Warning":"<warningMessage>",
    "Message":"<Message>",
    "Completion":"<compeletion>"
  }
}
```
