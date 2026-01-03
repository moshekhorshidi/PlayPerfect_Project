{% macro strip_purchase_id_prefix(column_name) %}

    regexp_replace({{ column_name }}, r'^pur_0*','')

{% endmacro %}