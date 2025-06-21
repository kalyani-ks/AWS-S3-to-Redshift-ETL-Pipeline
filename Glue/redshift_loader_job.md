## redshift_loader_job
 This etl glue job Loads Parquet data into Redshift.
 ```python

import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
import logging

logger = logging.getLogger('my_logger')
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
handler.setLevel(logging.INFO)
logger.addHandler(handler)

logger.info('Starting Glue Job 2: Parquet to Redshift Load')

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

logger.info(f"Job started with arguments: {args}")

# --- Configuration for Glue Job 2 ---
# Replace with your actual Glue Data Catalog database and table for Parquet data
GLUE_DATABASE_NAME = "db-01"
GLUE_PARQUET_TABLE_NAME = "processed_sales_file" # Name created by Crawler 2

# Replace with your Redshift Glue Connection name (created in Step 4)
REDSHIFT_CONNECTION_NAME = "SalesDataRedshift_connection"

# Replace with your Redshift database and target table name (created in Step 5)
REDSHIFT_DATABASE_NAME = "dev" # Or your specific Redshift database
REDSHIFT_TABLE_NAME = "sales_data_table" # Your target table in Redshift

# This is the S3 path Redshift will use for temporary staging during COPY operations.
# The IAM role associated with your REDSHIFT WORKGROUP (from Step 1) must have R/W access here.
REDSHIFT_TEMP_DIR = "s3://sales-data-etl-project-bucket/redshift-temp/"

logger.info(f"Reading Parquet data from Glue Data Catalog: {GLUE_DATABASE_NAME}.{GLUE_PARQUET_TABLE_NAME}")
# Read Parquet Data from Glue Data Catalog
parquet_dynamic_frame = glueContext.create_dynamic_frame.from_catalog(
    database=GLUE_DATABASE_NAME,
    table_name=GLUE_PARQUET_TABLE_NAME,
    transformation_ctx="parquet_source"
)
logger.info(f"Successfully read {parquet_dynamic_frame.toDF().count()} rows from Parquet source.")
logger.info(f"Schema of Parquet data: {str(parquet_dynamic_frame.schema())}")

logger.info(f"Writing data to Redshift table: {REDSHIFT_DATABASE_NAME}.{REDSHIFT_TABLE_NAME} using connection: {REDSHIFT_CONNECTION_NAME}")
# Write Data to Amazon Redshift
glueContext.write_dynamic_frame.from_jdbc_conf(
    frame=parquet_dynamic_frame,
    catalog_connection=REDSHIFT_CONNECTION_NAME,
    connection_options={
        "database": REDSHIFT_DATABASE_NAME,
        "dbtable": REDSHIFT_TABLE_NAME,
        "redshiftTmpDir": REDSHIFT_TEMP_DIR, # Required for Redshift COPY operations
        "aws_iam_role": "arn:aws:iam::183295412439:role/RedshiftETLprojectRole" # IMPORTANT: Redshift Workgroup's IAM Role ARN
    },
    redshift_tmp_dir=REDSHIFT_TEMP_DIR, # Redundant but good for clarity in some older versions
    transformation_ctx="redshift_target"
)
logger.info("Data successfully written to Redshift.")

job.commit()
logger.info("Glue Job 2 committed successfully.")

```
## IAM ROLE 
```

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
                "arn:aws:s3:::sales-data-etl-project-bucket",
                "arn:aws:s3:::sales-data-etl-project-bucket/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:ap-south-1:183295412439:log-group:/aws/glue/jobs/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "glue:GetDatabase",
                "glue:GetTable",
                "glue:GetPartition",
                "glue:UpdateTable"
            ],
            "Resource": [
                "arn:aws:glue:ap-south-1:183295412439:database/db-01",
                "arn:aws:glue:ap-south-1:183295412439:table/db-01/*",
                "arn:aws:glue:ap-south-1:183295412439:catalog"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:CreateSecret",
                "secretsmanager:PutSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DeleteSecret",
                "secretsmanager:PutResourcePolicy",
                "secretsmanager:ListSecrets"
            ],
            "Resource": "arn:aws:secretsmanager:ap-south-1:183295412439:secret:*"
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
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "arn:aws:iam::183295412439:role/RedshiftETLprojectRole"
        }
    ]
}

```

Trust relationship

```
"Condition": {
                "ArnEquals": { 
                    "aws:SourceArn": [
                         ,
                         "arn:aws:glue:ap-south-1:183295412439:job/redshift_loader_job"
                    ]

                },
                "StringsEquals": {
                    "aws:SourceAccount": "183295412439"
                }

           }

```

## Glue Connection for Redshift
For this job we need to create a Glue Connection for Redshift

### Prerequisites

1.**VPC Endpoints:**
 * S3 Endpoint
 * Redshift Endpoint
 * Secret Manager Endpoint
 * KMS Endpoint
 * STS Endpoint

2. **Security Group:**
 * Inbound rule for Redshift and a self-referencing rule
3.**IAM Role**
 * We'll use the same IAM role that we're using for `redshift_loader_job`.

### Connection creation
* Select Amazon Redshift as the Data Source.
* Select your Redshift Cluster, Database,provide credentials and IAM role.
* Finally review and create.
* After successful creation, test your connection.

