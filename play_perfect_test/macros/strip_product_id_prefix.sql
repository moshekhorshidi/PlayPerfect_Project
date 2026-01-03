{% macro strip_product_id_prefix(column_name) %}

    regexp_replace({{ column_name }}, r'^Shop_', '')

{% endmacro %}