from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryCreateEmptyTableOperator
from airflow.providers.google.cloud.operators.dataflow import DataflowTemplatedJobStartOperator

default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'data_pipeline',
    default_args=default_args,
    description='Data lake processing pipeline',
    schedule_interval=timedelta(hours=1),
    catchup=False,
)

create_table = BigQueryCreateEmptyTableOperator(
    task_id='create_processed_table',
    dataset_id='${dataset_id}',
    table_id='processed_events',
    project_id='${project_id}',
    dag=dag,
)

process_data = DataflowTemplatedJobStartOperator(
    task_id='process_streaming_data',
    template='gs://dataflow-templates/latest/Stream_DLP_GCS_Text_to_BigQuery',
    project_id='${project_id}',
    location='us-central1',
    dag=dag,
)

create_table >> process_data