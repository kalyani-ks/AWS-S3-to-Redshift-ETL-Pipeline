## csv-data-reader crawler
This crawler is created to crawl the input folder of bucket `sales-data-etl-project/input/` and  discover the schema of the newly added CSV file, and create/update  a table in the Glue Data Catalogue
## parquet-data-reader crawler
This crawler is created to crawl the folder `sales-data-etl-project/output/`  and  discover the schema of the newly added CSV file, and create/update  a table in the Glue Data Catalogue
## IAM ROLE 
We are using the common IAM role `role_for_crawler` for both crawlers
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::sales-data-etl-project",
                "arn:aws:s3:::sales-data-etl-project/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "glue:CreateTable",
                "glue:UpdateTable",
                "glue:DeleteTable",
                "glue:GetTable",
                "glue:GetTables",
                "glue:BatchCreatePartition",
                "glue:CreatePartition",
                "glue:UpdatePartition",
                "glue:DeletePartition",
                "glue:GetPartition",
                "glue:GetPartitions",
                "glue:BatchDeletePartition",
                "glue:GetDatabase",
                "glue:GetDatabases",
                "glue:CreateDatabase",
                "glue:UpdateDatabase",
                "glue:DeleteDatabase"
            ],
            "Resource": [
                "arn:aws:glue:ap-south-1:183295412439:catalog",
                "arn:aws:glue:ap-south-1:183295412439:database/db-01",
                "arn:aws:glue:ap-south-1:183295412439:database/*",
                "arn:aws:glue:ap-south-1:183295412439:table/db-01/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:ap-south-1:183295412439:log-group:/aws/glue/crawlers/*"
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
                "Service": "glue.amazonaws.com"
            },
            "Action": "sts:AssumeRole",
           "Condition": {
                 "ArnEquals": {
                       "aws:SourceArn": [
                               "arn:aws:glue:ap-south-1:183295412439:crawler/csv-data-reader",
                               "arn:aws:glue:ap-south-1:183295412439:crawler/parquet-data-reader"

                       ]
                 }
           },
               "StringsEquals": {
                      "aws:SourceAccount": "183295412439"
                }
                                                 
                                                
        }
    ]
}

```
