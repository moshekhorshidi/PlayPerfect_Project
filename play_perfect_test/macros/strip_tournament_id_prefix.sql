{% macro strip_tournament_id_prefix(column_name) %}

    regexp_replace({{ column_name }}, r'_0*', '')

{% endmacro %}