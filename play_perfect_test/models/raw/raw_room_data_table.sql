{{ config(materialized='view') }}

SELECT * FROM {{ source('raw_data_source', 'play_perfect_oltp') }}

