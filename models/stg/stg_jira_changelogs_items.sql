with source as (
    select * from targetboard_source_jira.changelogs__items
),

renamed as (
    select
        _sdc_source_key_id  as changelog_id,
        field   as field_name,
        fieldtype  as field_type,
        "fromString" as from_value,
        "toString"  as to_value
    from source
)

select * from renamed