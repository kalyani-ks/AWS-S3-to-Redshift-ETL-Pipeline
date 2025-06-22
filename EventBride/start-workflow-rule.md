## start-workflow-rule

This EventBride rule will invoke  Lambda function when a new object is added to the bucket.


 **Event Pattern**
```json
 {
  "source": ["aws.s3"],
  "detail-type": ["Object Created"],
  "detail": {
    "bucket": {
      "name": ["sales-data-etl-project-bucket"]
    }
  }
}
 ```

**IAM Role**

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": [
                "arn:aws:lambda:ap-south-1:183295412439:function:start_workflow_function"
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
            "Action": "sts:AssumeRole"
        }
    ]
}
```

*While creating this rule,select `matched events`  in configure target input
