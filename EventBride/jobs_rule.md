## Event Pattern for jobs_rule
These rules are designed for jobs to handle Glue Job State Changes, which are published in an SNS topic.

**job01_rule**
```json
{
  "source": ["aws.glue"],
  "detail-type": ["Glue Job State Change"],
  "detail": {
    "state": ["SUCCEEDED", "FAILED"],
    "jobName": ["job01ks"]
  }
}
```
**IAM role for job01_rule**
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
                "arn:aws:sns:ap-south-1:183295412439:Etl-Notifiction"
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
                    "aws:SourceArn": "arn:aws:events:ap-south-1:183295412439:rule/job01_rule"
                }

           }
        }
    ]
}
```

## Event Pattern for job02_rule
```json
{
  "source": ["aws.glue"],
  "detail-type": ["Glue Job State Change"],
  "detail": {
    "state": ["SUCCEEDED", "FAILED"],
    "jobName": ["redshift-loader-job"]
  }
}
```

**IAM role for job01_rule**
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
                "arn:aws:sns:ap-south-1:183295412439:Etl-Notifiction"
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
                    "aws:SourceArn": "arn:aws:events:ap-south-1:183295412439:rule/job02_rule"
                }

           }
        }
    ]
}
```

* While creating both rules, select `input transformer` in the configure target input
* Configure `input transformer` with following,
  
**Input_path**
  
  ```json
 
{
  "jobName": "$.detail.jobName",
  "message": "$.detail.message",
  "status": "$.detail.state",
  "time": "$.time"
}
```

**Template**
```json
{
  "Glue Job Notification":
  {
    "Job Name": "<jobName>",
    "Status": "<status>",
    "Time": "<time>",
    "Message": "<message>"
    }
}
```
