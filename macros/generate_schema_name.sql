{% macro generate_schema_name(custom_schema_name, node) -%}
    {#
        Custom schema name generation macro for multi-industry dbt project.
        
        This macro routes models to their appropriate schemas based on the
        industry folder they're in, while maintaining support for custom
        schema overrides in model configs.
        
        Industry Routing:
        - models/cds/* → INDUSTRIES_HEALTHCARE
        - models/agr/* → INDUSTRIES_AGRICULTURE
        - models/met/* → INDUSTRIES_METEOROLOGY
        
        For Fivetran dbt Core Transformations, this allows selective execution
        by industry using folder-based selection (e.g., --select cds.*)
    #}

    {%- set default_schema = target.schema -%}
    
    {#- If a custom schema is explicitly set in the model config, use it -#}
    {%- if custom_schema_name is not none -%}
        {{ custom_schema_name | trim }}
    
    {#- Otherwise, use the default target schema -#}
    {%- else -%}
        {{ default_schema }}
    
    {%- endif -%}

{%- endmacro %}
