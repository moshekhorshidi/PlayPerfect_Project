
WITH base AS (
    SELECT 
        *
    FROM {{ ref ('stg_event_stream') }}

), daily_Build AS (

SELECT 
-- engagement block
    EXTRACT(YEAR FROM DATE) AS year_of_daily,
    EXTRACT(MONTH FROM DATE) AS month_of_daily,
    EXTRACT(DAY FROM DATE) AS day_of_daily,
    DATE,
    Player_ID,
-- game play 
    STRING_AGG(DISTINCT CAST(Players_Capacity AS STRING), ", ") AS capacity_of_daily, 
    SUM(Play_Duration) AS duration_of_daily,
    COUNT(CASE WHEN event_name = 'Tournament Joined' THEN event_name ELSE NULL END) AS total_joined_of_daily,
    STRING_AGG(DISTINCT CAST(Score AS STRING), ", ") AS scored_of_daily,
    MIN(CASE WHEN Score <> 0 then score end) AS min_not_zero_score_of_daily, 
    MAX(Score) AS max_score_of_daily,
    STRING_AGG(DISTINCT CAST(Position AS STRING), ", ") AS position_of_daily,
    MIN(CASE WHEN Position <> 0 then Position end) AS min_not_zero_Position_of_daily, 
    MAX(Position) AS max_position_of_daily,
    MIN(NULLIF(Position, 0)) = MAX(Position) AS Bool_for_position_of_daily,
-- monetization block
    COUNT(CASE WHEN event_name = 'Purchase' THEN event_name ELSE NULL END) AS count_purchase_of_daily, 
    SUM(Balance_Before) AS balance_of_daily, 
    SUM(Entry_Fee) AS entry_fee_of_daily, 
    SUM(Coins_Spent) AS coins_spent_of_daily,
    SUM(Price_USD) AS gross_revenue_of_daily,
    SUM(IFNULL(Reward, 0) + IFNULL(Coins_Claimed, 0)) - SUM(IFNULL(Entry_Fee, 0) + IFNULL(Coins_Spent, 0)) AS net_coins_delta_of_daily,
    CASE WHEN SUM(Price_USD) > 0 THEN True ELSE False END AS is_payer_of_daily
FROM base
GROUP BY Player_ID, DATE
ORDER BY Player_ID asc, day_of_daily asc

) , final AS (

SELECT 
-- engagement block
    year_of_daily,
    month_of_daily,
    day_of_daily,
    DATE AS date_of_daily,
    Player_ID AS player_id_daily,
 -- game play 
    capacity_of_daily, 
    duration_of_daily,
    total_joined_of_daily,
    scored_of_daily,
    min_not_zero_score_of_daily, 
    max_score_of_daily,
    position_of_daily,
    min_not_zero_Position_of_daily, 
    max_position_of_daily,
    Bool_for_position_of_daily,
-- monetization block
    count_purchase_of_daily, 
    balance_of_daily, 
    entry_fee_of_daily, 
    coins_spent_of_daily,
    gross_revenue_of_daily,
    net_coins_delta_of_daily,
    is_payer_of_daily

FROM daily_Build

)

SELECT * FROM final
ORDER BY date_of_daily asc , player_id_daily asc 
    

