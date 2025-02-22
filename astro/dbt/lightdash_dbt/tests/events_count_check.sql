SELECT event_id
FROM {{ ref('events_stg') }}
WHERE otime = now()::date