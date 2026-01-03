WITH columns_renamed AS (
    
SELECT 
    
    timestamp_utc AS TIMESTAMP,
    date_utc AS DATE,
    event_name AS Event_Name,
    player_id AS Player_ID,
    level AS LEVEL,
    balance_before AS Balance_Before,
    country_code AS Country_Code,
    tournament_id Tournament_ID,
    room_id AS Room_ID,
    entry_fee AS Entry_Fee,
    coins_spent AS Coins_Spent,
    players_capacity AS Players_Capacity,
    play_duration AS Play_Duration,
    score AS Score,
    position AS Position,
    reward AS Reward,
    coins_claimed AS Coins_Claimed,
    purchase_id AS Purchase_ID,
    product_id AS Product_ID,
    price_usd AS Price_USD

FROM {{ ref('raw_room_data_table') }}

) , columns_modified AS (

    SELECT 
        TIMESTAMP,
        DATE,
        {{ clean_event_names_case('event_name') }} AS event_name,
        {{ strip_player_prefix('Player_ID') }} AS Player_ID,
        LEVEL,
        Balance_Before,
        Country_Code,
        {{ strip_tournament_id_prefix('Tournament_ID') }} AS Tournament_ID,
        {{ strip_room_id_prefix('Room_ID') }} AS Room_ID,
        Entry_Fee,
        Coins_Spent,
        Players_Capacity,
        ROUND(Play_Duration,3) AS Play_Duration,
        Score,
        Position,
        Reward,
        Coins_Claimed,
        {{ strip_purchase_id_prefix('Purchase_ID') }} AS Purchase_ID,
        {{ strip_product_id_prefix('Product_ID') }} AS Product_ID,
        Price_USD

    FROM columns_renamed

) , nulls_handled AS (

    SELECT 
        TIMESTAMP,
        DATE,
        event_name,
        Player_ID,
        LEVEL,
        COALESCE(Balance_Before,0) AS Balance_Before,
        Country_Code,
        Tournament_ID,
        Room_ID,
        COALESCE(Entry_Fee,0) AS Entry_Fee,
        COALESCE(Coins_Spent,0) AS Coins_Spent,
        COALESCE(Players_Capacity,0) AS Players_Capacity,
        Play_Duration,
        COALESCE(Score,0) AS Score,
        COALESCE(Position,0) AS Position,
        COALESCE(Reward,0) AS Reward,
        COALESCE(Coins_Claimed,0) AS Coins_Claimed,
        Purchase_ID,
        Product_ID,
        COALESCE(Price_USD,0.0) AS Price_USD

    FROM columns_modified

) , final AS (

    SELECT 
        TIMESTAMP,
        DATE,
        event_name,
        Player_ID,
        LEVEL,
        Balance_Before,
        Country_Code,
        Tournament_ID,
        Room_ID,
        Entry_Fee,
        Coins_Spent,
        Players_Capacity,
        Play_Duration,
        Score,
        Position,
        Reward,
        Coins_Claimed,
        Purchase_ID,
        Product_ID,
        Price_USD

    FROM nulls_handled

)

SELECT * FROM final