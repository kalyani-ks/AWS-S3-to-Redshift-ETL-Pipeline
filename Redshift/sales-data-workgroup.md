## sales-data-workgroup
We will create a workgroup(`sales-data-workgroup`) and a namespace (`sales-data-namespace`).

*Attach the following IAM Role  to the  workgroup*

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::sales-data-etl-project",
                "arn:aws:s3:::sales-data-etl-project/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt",
                "kms:GenerateDataKey",
                "kms:DescribeKey",
                "kms:ListKeys",
                "kms:ListAliases"
            ],
            "Resource": "arn:aws:kms:ap-south-1:183295412439:key/*"
        }
    ]
}
```
