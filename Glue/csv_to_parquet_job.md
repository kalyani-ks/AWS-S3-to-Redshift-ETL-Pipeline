## csv_to_parquet_job
This glue etl job read the csv data and transform it into parquet format.

```python

import sys
import logging

from awsglue.transforms import ApplyMapping
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

# Specific imports for Data Quality and Spark SQL functions
from awsgluedq.transforms import EvaluateDataQuality
from pyspark.sql import functions as F
from pyspark.sql.types import DateType


## Logging Configuration
logger = logging.getLogger(__name__) # Use __name__ for better log identification
logger.setLevel(logging.INFO)

# Create a handler for CloudWatch logging
handler = logging.StreamHandler()
handler.setLevel(logging.INFO)
logger.addHandler(handler)

logger.info("Starting Glue Job 1: CSV to Parquet Transformation")


## Job Initialization

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

logger.info(f"Job started with arguments: {args}")


## Configuration / Constants

# Source Data Catalog details for CSV input
GLUE_CATALOG_DATABASE = "db-01"
GLUE_CATALOG_TABLE_NAME = "input"

# Target S3 path for processed Parquet files
TARGET_S3_PATH = "s3://sales-data-etl-project-bucket/output/processed-sales-file/"

# Date format expected in the input CSV columns
# IMPORTANT: Adjust this format to match your actual CSV date strings!
# Examples: "MM/dd/yyyy" for 01/25/2023, "yyyy-MM-dd" for 2023-01-25
DATE_INPUT_FORMAT = "M/d/yyyy"

# Default ruleset for AWS Glue Data Quality evaluation
DEFAULT_DATA_QUALITY_RULESET = """
    Rules = [
        ColumnCount > 0
    ]
"""

# List of columns to select for the final output
FINAL_SELECTED_COLUMNS = [
    "country", "item_type", "order_date", "order_id", "ship_date",
    "units_sold", "unit_price", "total_revenue", "total_cost", "total_profit"
]


## 1. Read Data from Glue Data Catalog

logger.info(f"Reading data from Glue Data Catalog: {GLUE_CATALOG_DATABASE}.{GLUE_CATALOG_TABLE_NAME}")
source_dynamic_frame = glueContext.create_dynamic_frame.from_catalog(
    database=GLUE_CATALOG_DATABASE,
    table_name=GLUE_CATALOG_TABLE_NAME,
    transformation_ctx="source_dynamic_frame"
)
logger.info("Successfully read data from Glue Data Catalog.")

# Log schema and row count for initial data
logger.info("Schema of input data:")
source_dynamic_frame.printSchema() # Prints formatted schema
logger.info(f"Number of rows in input data: {source_dynamic_frame.toDF().count()}")



## 2. Apply Schema Changes & Column Renaming (ApplyMapping)

logger.info("Applying initial schema mapping and renaming columns...")
mapped_dynamic_frame = ApplyMapping.apply(
    frame=source_dynamic_frame,
    mappings=[
        ("region", "string", "region", "string"),
        ("country", "string", "country", "string"),
        ("item type", "string", "item_type", "string"),
        ("sales channel", "string", "sales_channel", "string"),
        ("order priority", "string", "order_priority", "string"),
        ("order date", "string", "order_date_str", "string"), # Temporarily rename for date conversion
        ("order id", "long", "order_id", "long"),
        ("ship date", "string", "ship_date_str", "string"),   # Temporarily rename for date conversion
        ("units sold", "long", "units_sold", "long"),
        ("unit price", "double", "unit_price", "double"),
        ("unit cost", "double", "unit_cost", "double"),
        ("total revenue", "double", "total_revenue", "double"),
        ("total cost", "double", "total_cost", "double"),
        ("total profit", "double", "total_profit", "double")
    ],
    transformation_ctx="mapped_dynamic_frame"
)
logger.info("Initial schema mapping and column renaming applied.")



## 3. Convert Date Columns to DateType

logger.info("Converting date columns to DateType...")
# Convert DynamicFrame to Spark DataFrame for date transformations
temp_df = mapped_dynamic_frame.toDF()

# Convert 'order_date_str' to DateType and rename to 'order_date'
temp_df = temp_df.withColumn(
    "order_date",
    F.to_date(F.col("order_date_str"), DATE_INPUT_FORMAT).cast(DateType())
).drop("order_date_str") # Drop the temporary string column

# Convert 'ship_date_str' to DateType and rename to 'ship_date'
temp_df = temp_df.withColumn(
    "ship_date",
    F.to_date(F.col("ship_date_str"), DATE_INPUT_FORMAT).cast(DateType())
).drop("ship_date_str") # Drop the temporary string column

# Convert the Spark DataFrame back to a DynamicFrame
transformed_dynamic_frame = DynamicFrame.fromDF(temp_df, glueContext, "transformed_dynamic_frame")
logger.info("Date columns converted.")
logger.info("Schema after date conversion:")
transformed_dynamic_frame.printSchema()



## 4. Handle Null Values

logger.info("Handling null values...")

def replace_nulls(dataframe):
    """
    Replaces null values in string columns with 'NA' and numeric columns with 0.
    Args:
        dataframe (DataFrame): The input Spark DataFrame.
    Returns:
        DataFrame: The DataFrame with nulls replaced.
    """
    for col_name, data_type in dataframe.dtypes:
        if data_type in ('string', 'string_type'):
            dataframe = dataframe.fillna('NA', subset=[col_name])
        elif data_type in ('int', 'int_type', 'long', 'long_type', 'double', 'double_type', 'decimal', 'decimal_type'):
            dataframe = dataframe.fillna(0, subset=[col_name])
    return dataframe

# Convert to Spark DataFrame, apply null handling, then convert back to DynamicFrame
nulls_handled_dynamic_frame = DynamicFrame.fromDF(replace_nulls(transformed_dynamic_frame.toDF()),glueContext,"nulls_handled_dynamic_frame")
logger.info("Null values handled.")



## 5. Select Final Columns

logger.info(f"Selecting final columns: {FINAL_SELECTED_COLUMNS}")
final_processed_dynamic_frame = nulls_handled_dynamic_frame.select_fields(FINAL_SELECTED_COLUMNS)
logger.info("Final columns selected.")
logger.info("Schema of final processed data:")
final_processed_dynamic_frame.printSchema()


## 6. Evaluate Data Quality

logger.info("Evaluating data quality...")
# The process_rows method directly modifies the frame, but we'll assign it
# to a new variable for clarity in the flow.
EvaluateDataQuality().process_rows(
    frame=final_processed_dynamic_frame,
    ruleset=DEFAULT_DATA_QUALITY_RULESET,
    publishing_options={
        "dataQualityEvaluationContext": "data_quality_evaluation_context",
        "enableDataQualityResultsPublishing": True
    },
    additional_options={
        "dataQualityResultsPublishing.strategy": "BEST_EFFORT",
        "observations.scope": "ALL"
    }
)
logger.info("Data quality evaluation completed.")



## 7. Write Data to S3 (Parquet)

logger.info(f"Writing processed data to S3: {TARGET_S3_PATH}")
glueContext.write_dynamic_frame.from_options(
    frame=final_processed_dynamic_frame, # Use the frame after DQ evaluation
    connection_type="s3",
    format="glueparquet",
    connection_options={
        "path": TARGET_S3_PATH,
        "partitionKeys": [] # Assuming no partitioning for now based on your code
    },
    format_options={
        "compression": "snappy"
    },
    transformation_ctx="s3_parquet_sink"
)
logger.info("Data successfully written to S3 in Parquet format.")


## Job Commit

job.commit()
logger.info("Glue Job 1 committed successfully.")

```
