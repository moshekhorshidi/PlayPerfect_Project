SELECT 
    DATE,
    Room_ID,
    Tournament_ID,
    MIN_BY(Player_ID, CASE WHEN Position = 1 THEN Position END) as winner,
    SUM(COUNTIF(Position = 1 and event_name = 'Tournament Room Closed')) OVER (PARTITION BY Room_ID, DATE, Tournament_ID ) AS winner_count
FROM {{ ref('stg_event_stream') }}
WHERE event_name <> 'Purchase'
GROUP BY Room_ID, DATE, Tournament_ID
QUALIFY winner_count > 1
ORDER BY DATE DESC