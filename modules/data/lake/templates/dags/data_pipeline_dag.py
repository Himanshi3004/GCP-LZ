"""
Data Pipeline DAG Template
Orchestrates data ingestion, processing, and storage workflows
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import (
    BigQueryCreateDatasetOperator,
    BigQueryCreateEmptyTableOperator,
    BigQueryInsertJobOperator,
)
from airflow.providers.google.cloud.operators.dataflow import (
    DataflowCreateJavaJobOperator,
    DataflowCreatePythonJobOperator,
)
from airflow.providers.google.cloud.operators.gcs import (
    GCSCreateBucketOperator,
    GCSDeleteObjectsOperator,
    GCSListObjectsOperator,
)
from airflow.providers.google.cloud.operators.pubsub import (
    PubSubCreateTopicOperator,
    PubSubPublishMessageOperator,
)
from airflow.providers.google.cloud.sensors.gcs import GCSObjectExistenceSensor
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from airflow.operators.python import PythonOperator
from airflow.operators.dummy import DummyOperator

# Configuration
PROJECT_ID = "${project_id}"
REGION = "${region}"
ENVIRONMENT = "${environment}"
DATASET_ID = "${dataset_id}"
GCS_BUCKET = "${gcs_bucket}"
DATAFLOW_TEMPLATE = "${dataflow_template}"

# Default arguments
default_args = {
    'owner': 'data-engineering',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
    'catchup': False,
}

# DAG definition
dag = DAG(
    'data_pipeline',
    default_args=default_args,
    description='Comprehensive data pipeline for ingestion and processing',
    schedule_interval=timedelta(hours=1),
    max_active_runs=1,
    tags=['data', 'pipeline', 'etl'],
)

# Start task
start_task = DummyOperator(
    task_id='start_pipeline',
    dag=dag,
)

# Check for new data files
check_new_data = GCSObjectExistenceSensor(
    task_id='check_new_data',
    bucket=GCS_BUCKET,
    object='raw/{{ ds }}/',
    timeout=300,
    poke_interval=60,
    dag=dag,
)

# List objects for processing
list_objects = GCSListObjectsOperator(
    task_id='list_objects',
    bucket=GCS_BUCKET,
    prefix='raw/{{ ds }}/',
    dag=dag,
)

# Data validation function
def validate_data(**context):
    """Validate incoming data files"""
    import logging
    from google.cloud import storage
    
    client = storage.Client()
    bucket = client.bucket(GCS_BUCKET)
    
    objects = context['task_instance'].xcom_pull(task_ids='list_objects')
    valid_files = []
    
    for obj_name in objects:
        blob = bucket.blob(obj_name)
        # Add validation logic here
        if blob.size > 0:
            valid_files.append(obj_name)
            logging.info(f"Valid file: {obj_name}")
        else:
            logging.warning(f"Empty file: {obj_name}")
    
    return valid_files

# Validate data
validate_data_task = PythonOperator(
    task_id='validate_data',
    python_callable=validate_data,
    dag=dag,
)

# Process data with Dataflow
process_data = DataflowCreatePythonJobOperator(
    task_id='process_data',
    py_file=DATAFLOW_TEMPLATE,
    job_name='data-processing-{{ ds_nodash }}-{{ ts_nodash }}',
    options={
        'project': PROJECT_ID,
        'region': REGION,
        'staging_location': f'gs://{GCS_BUCKET}/staging/',
        'temp_location': f'gs://{GCS_BUCKET}/temp/',
        'input_path': f'gs://{GCS_BUCKET}/raw/{{{{ ds }}}}/',
        'output_path': f'gs://{GCS_BUCKET}/processed/{{{{ ds }}}}/',
        'runner': 'DataflowRunner',
        'autoscaling_algorithm': 'THROUGHPUT_BASED',
        'max_num_workers': 10,
        'machine_type': 'n1-standard-2',
    },
    dag=dag,
)

# Load processed data to BigQuery
load_to_bigquery = GCSToBigQueryOperator(
    task_id='load_to_bigquery',
    bucket=GCS_BUCKET,
    source_objects=['processed/{{ ds }}/*.json'],
    destination_project_dataset_table=f'{PROJECT_ID}.{DATASET_ID}.processed_data',
    source_format='NEWLINE_DELIMITED_JSON',
    write_disposition='WRITE_APPEND',
    create_disposition='CREATE_IF_NEEDED',
    autodetect=True,
    dag=dag,
)

# Data quality checks
data_quality_check = BigQueryInsertJobOperator(
    task_id='data_quality_check',
    configuration={
        'query': {
            'query': f"""
                SELECT 
                    COUNT(*) as total_records,
                    COUNT(DISTINCT id) as unique_records,
                    COUNTIF(id IS NULL) as null_ids,
                    CURRENT_TIMESTAMP() as check_timestamp
                FROM `{PROJECT_ID}.{DATASET_ID}.processed_data`
                WHERE DATE(_PARTITIONTIME) = '{{{{ ds }}}}'
            """,
            'useLegacySql': False,
            'destinationTable': {
                'projectId': PROJECT_ID,
                'datasetId': DATASET_ID,
                'tableId': 'data_quality_metrics'
            },
            'writeDisposition': 'WRITE_APPEND',
            'createDisposition': 'CREATE_IF_NEEDED'
        }
    },
    dag=dag,
)

# Cleanup temporary files
cleanup_temp = GCSDeleteObjectsOperator(
    task_id='cleanup_temp',
    bucket_name=GCS_BUCKET,
    prefix='temp/{{ ds }}/',
    dag=dag,
)

# Publish completion notification
publish_notification = PubSubPublishMessageOperator(
    task_id='publish_notification',
    project_id=PROJECT_ID,
    topic='data-pipeline-notifications',
    messages=[{
        'data': '{"pipeline": "data_pipeline", "status": "completed", "date": "{{ ds }}", "environment": "' + ENVIRONMENT + '"}',
        'attributes': {
            'pipeline': 'data_pipeline',
            'status': 'completed',
            'environment': ENVIRONMENT
        }
    }],
    dag=dag,
)

# End task
end_task = DummyOperator(
    task_id='end_pipeline',
    dag=dag,
)

# Task dependencies
start_task >> check_new_data >> list_objects >> validate_data_task
validate_data_task >> process_data >> load_to_bigquery >> data_quality_check
data_quality_check >> cleanup_temp >> publish_notification >> end_task