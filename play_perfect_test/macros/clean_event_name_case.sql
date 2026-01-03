{% macro clean_event_names_case(column_name) %}

    CASE {{ column_name }}
        WHEN 'purchase' THEN 'Purchase'
        WHEN 'tournamentFinished' THEN 'Tournament Finished'
        WHEN 'tournamentRoomClosed' THEN 'Tournament Room Closed'
        WHEN 'tournamentRewardClaimed' THEN 'Tournament Reward Claimed'
        WHEN 'tournamentJoined' THEN 'Tournament Joined'
        ELSE {{ column_name }}
    END

{% endmacro %}