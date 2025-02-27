{{
  config(
    materialized='materialized_view',
    target_schema='marts'
  )
}}

SELECT
    *
FROM {{ ref('events_stg') }}