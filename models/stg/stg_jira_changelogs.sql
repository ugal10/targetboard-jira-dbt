with source as (
    select * from targetboard_source_jira.changelogs
),

renamed as (
    select
        id as changelog_id,
        "issueId"  as issue_id,
        created as changed_at,
        _sdc_extracted_at as extracted_at
    from source
)

select * from renamed