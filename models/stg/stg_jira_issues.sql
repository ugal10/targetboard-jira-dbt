with source as (
    select * from targetboard_source_jira.issues
),

renamed as (
    select
        id as issue_id,
        key as issue_key,
        fields__summary as summary,
        fields__issuetype__name as issue_type,
        fields__status__name as current_status,
        fields__project__key as project_key,
        fields__project__name as project_name,
        "fields__assignee__displayName" as assignee_name,
        "fields__reporter__displayName"  as reporter_name,
        fields__created   as created_at,
        fields__updated  as updated_at,
        _sdc_extracted_at as extracted_at
    from source
)

select * from renamed