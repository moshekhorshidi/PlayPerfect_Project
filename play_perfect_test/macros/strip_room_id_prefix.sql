{% macro strip_room_id_prefix(column_name) %}

    regexp_replace({{ column_name }}, r'^room_0*', '')

{% endmacro %}