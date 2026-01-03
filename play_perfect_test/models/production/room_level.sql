WITH base AS (
    SELECT 
        *
    FROM {{ ref ('stg_event_stream') }}

), room_build AS (

SELECT 
-- room level block
    EXTRACT(YEAR FROM DATE) AS YEAR,
    EXTRACT(MONTH FROM DATE) AS MONTH,
    EXTRACT(DAY FROM DATE) AS DAY,
    DATE,
    Room_ID,
    Players_Capacity,
    STRING_AGG(DISTINCT CAST( tournament_id AS STRING), ", ") AS room_tournaments,
    STRING_AGG(DISTINCT Player_ID, ", ") AS participation_players_list,
    STRING_AGG(DISTINCT CAST( Country_Code AS STRING), ", ") AS room_players_locations,
    COUNT(DISTINCT Player_ID) AS total_players,
    STRING_AGG(DISTINCT CAST( level AS STRING), ", ") AS room_players_levels,
    MAX(Level) AS room_top_level_player,
    COALESCE(ROUND(SUM(Play_Duration),3),0) AS room_duration,
-- game play 
    STRING_AGG(DISTINCT CAST(Score AS STRING), ", ") AS scored_in_room,
    MAX(Score) AS highest_score,
    MIN_BY(Player_ID, CASE WHEN Position = 1 THEN Position END) AS winner_player_id,
    MIN_BY( Country_Code, CASE WHEN Position = 1 THEN Position END) AS room_winner_location,
    MAX_BY(Player_ID, Score) AS room_top_score_player_id,
-- monetization block
    SUM(CASE WHEN event_name = 'Tournament Joined' THEN Entry_Fee ELSE NULL END) AS total_entry_fee_for_room, 
    SUM(IFNULL(Entry_Fee, 0)) - SUM(CASE WHEN event_name = 'Tournament Reward Claimed' THEN Reward ELSE NULL END) AS total_net_fee_for_room,
    SUM(
    SUM(CASE WHEN event_name = 'Tournament Joined' THEN balance_before ELSE 0 END) - 
    SUM(CASE WHEN event_name = 'Tournament Finished' THEN balance_before ELSE 0 END)
    ) OVER (PARTITION BY DATE ORDER BY DATE) AS room_tournament_balance_change
FROM base
WHERE event_name <> 'Purchase'
GROUP BY Room_ID, DATE, Players_Capacity
ORDER BY Room_ID

) , final AS (

SELECT 
    -- room level block
    YEAR,
    MONTH,
    DAY,
    DATE,
    Room_ID,
    Players_Capacity,
    room_tournaments,
    participation_players_list,
    room_players_locations,
    total_players,
    room_players_levels,
    room_top_level_player,
    room_duration,
    -- game play block
    scored_in_room,
    highest_score,
    winner_player_id,
    room_winner_location,
    room_top_score_player_id,
    -- monetization block
    total_entry_fee_for_room, 
    total_net_fee_for_room,
    room_tournament_balance_change

FROM room_build ) 

SELECT * FROM final
ORDER BY DATE DESC, Room_ID ASC




