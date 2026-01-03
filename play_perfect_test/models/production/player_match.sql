
SELECT 
-- UNIQE COMPOSIT KEY ADD
    CONCAT(Player_ID, Room_ID) AS player_room_id,
-- this is the the table catgorized by player and room
    DATE,
    Player_ID,
    Room_ID,
-- the currency movement block 
    MAX(Balance_Before) AS balance,
    MIN(Entry_Fee) AS Entry_Fee,
    MAX(Coins_Spent) AS coins_spent,
-- the game play block  
    ROUND(ANY_VALUE(Players_Capacity),3) AS CAPACITY,
    ANY_VALUE(Play_Duration) AS Play_Duration,
    MAX(CASE WHEN event_name = 'Tournament Finished' THEN Score ELSE NULL END) AS SCORE,
    MAX(Position) AS POSITION,
-- the rewards block  
    MAX(Reward) AS reward,
    MAX(Coins_Claimed) AS Coins_Claimed
FROM {{ ref ('stg_event_stream') }}
WHERE event_name <> 'Purchase'
GROUP BY DATE, Player_ID, Room_ID
ORDER BY PLAYER_ID asc, ROOM_ID asc







