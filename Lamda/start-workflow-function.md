## Start-workflow-unction
 This Lambda function receives an event via event bridge, then performs some checks and starts the Glue workflow.

 ```python

import json
import boto3
import urllib.parse
import logging

# --- Logging Configuration ---
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO) # Set logging level (INFO for general, DEBUG for detailed)

# --- AWS Client Initialization ---
glue_client = boto3.client('glue', region_name='ap-south-1')
sns_client = boto3.client('sns', region_name='ap-south-1') # Initialize SNS client

# --- Configuration ---
GLUE_WORKFLOW_NAME = "sales-data-workflow" 
SNS_TOPIC_ARN = "arn:aws:sns:ap-south-1:183295412439:sales-data-topic"

def publish_sns_message(subject, message):
    """
    Helper function to publish a message to the configured SNS topic.
    """
    try:
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=f"{message}\n\n🚀 Sent by Lambda: start-workflow-function"
        )
        logger.info(f"SNS notification sent. Subject: {subject}")
    except Exception as e:
        logger.error(f"Failed to publish SNS message: {str(e)}")

def lambda_handler(event, context):
    logger.info("Lambda function triggered by S3 event.")
    logger.info(f"Received event: {json.dumps(event)}")

    bucket_name = None
    object_key = None

    # --- Event Parsing: Handle S3 events from various sources ---
    # This logic covers S3 events routed through CloudWatch Events/EventBridge
    # AND direct S3 event notifications (more common for S3 bucket triggers).
    if 'detail' in event and 'bucket' in event['detail'] and 'name' in event['detail']['bucket'] \
       and 'object' in event['detail'] and 'key' in event['detail']['object']:
        # S3 event via CloudWatch Events/EventBridge (e.g., from an EventBridge rule)
        bucket_name = event['detail']['bucket']['name']
        object_key = urllib.parse.unquote_plus(event['detail']['object']['key'], encoding='utf-8')
        logger.info(f"Parsed S3 event from CloudWatch Events: bucket='{bucket_name}', key='{object_key}'")
    elif 'Records' in event and len(event['Records']) > 0 and 's3' in event['Records'][0]:
        # Direct S3 event notification (e.g., from an S3 bucket event configuration)
        s3_record = event['Records'][0]['s3']
        bucket_name = s3_record['bucket']['name']
        object_key = urllib.parse.unquote_plus(s3_record['object']['key'], encoding='utf-8')
        logger.info(f"Parsed direct S3 event: bucket='{bucket_name}', key='{object_key}'")
    else:
        error_message = "Error: Received an unhandled event structure. Expected S3 event via direct notification or CloudWatch Events."
        logger.error(error_message)
        publish_sns_message("Lambda Trigger FAILED - Unhandled Event", error_message + f"\nEvent: {json.dumps(event)}")
        return {
            'statusCode': 400,
            'body': json.dumps(error_message)
        }

    # --- File Type and Path Validation ---
    if not object_key.startswith('input/') or not object_key.endswith('.csv'):
        info_message = f"Skipping file: {object_key}. Not a valid CSV in the input folder."
        logger.info(info_message)
 
        #publish_sns_message("Lambda Trigger INFO - File Skipped", info_message) 
        return {
            'statusCode': 200,
            'body': json.dumps(info_message)
        }

    logger.info(f"Valid CSV '{object_key}' detected. Proceeding to trigger Glue Workflow '{GLUE_WORKFLOW_NAME}'.")

    # --- Trigger Glue Workflow ---
    try:
        response = glue_client.start_workflow_run(
            Name=GLUE_WORKFLOW_NAME
        )

        workflow_run_id = response['RunId']
        success_message = (
            f"SUCCESS: Lambda triggered Glue Workflow '{GLUE_WORKFLOW_NAME}' successfully."
            f"\nBucket: {bucket_name}"
            f"\nKey: {object_key}"
            f"\nGlue Workflow Run ID: {workflow_run_id}"
        )
        logger.info(success_message)
        publish_sns_message("Lambda Trigger SUCCESS - Glue Workflow Started", success_message)

        return {
            'statusCode': 200,
            'body': json.dumps(success_message)
        }

    except glue_client.exceptions.EntityNotFoundException:
        error_message = (
            f"Error: Glue Workflow '{GLUE_WORKFLOW_NAME}' not found."
            f" Please verify the workflow name and ensure the Lambda's IAM role has glue:StartWorkflowRun permission."
        )
        logger.error(error_message)
        publish_sns_message("Lambda Trigger FAILED - Glue Workflow Not Found", error_message)
        return {
            'statusCode': 404,
            'body': json.dumps(error_message)
        }
    except Exception as e:
        error_message = f"An unexpected error occurred while trying to start Glue Workflow '{GLUE_WORKFLOW_NAME}': {str(e)}"
        logger.error(error_message)
        publish_sns_message("Lambda Trigger FAILED - Unexpected Error", error_message + f"\nEvent: {json.dumps(event)}")
        return {
            'statusCode': 500,
            'body': json.dumps(error_message)
        }

```

## IAM Role for lamda 

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource":  [
                "arn:aws:logs:ap-south-1:183295412439:log-group:/lambda/lambda-glue-trigger-role/*"
            ]
        },
        {
            "Sid": "snsPublish",
            "Effect": "Allow",
            "Action": "sns:Publish",
            "Resource": "arn:aws:sns:ap-south-1:183295412439:sales-data-topic"
        },
         {
            "Effect": "Allow",
            "Action": "glue:StartWorkflowRun",
            "Resource": "arn:aws:glue:ap-south-1:183295412439:workflow/sales-data-workflow"
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
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                
                "StringsEquals": {
                    "aws:SourceAccount": "183295412439"
                },
                "ArnLike": {
                    "aws:SourceArn": "arn:aws:lambda:ap-south-1:183295412439:function:start-workflow-function"
                }

           }
        }
    ]
} 
```
