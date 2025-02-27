# dags/lightdash_dbt_runner.py

from cosmos.providers.dbt.dag import DbtDag
from airflow.datasets import Dataset
from datetime import datetime

lightdash_dbt = DbtDag(
    dag_id="lightdash_dbt",
    dbt_project_name="lightdash_dbt",
    start_date=datetime(2023, 1, 1),
    schedule=[Dataset(f"SEED://LIGHTDASH_DBT")],
    conn_id="postgres",
    dbt_args={
        "schema": "public",
        "dbt_executable_path": "/usr/local/airflow/dbt_venv/bin/dbt",
        },
)

lightdash_dbt