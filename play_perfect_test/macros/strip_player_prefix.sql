{% macro strip_player_prefix(column_name) %}

    regexp_replace({{ column_name }}, r'^p_0*', '')

{% endmacro %}