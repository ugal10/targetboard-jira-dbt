with source as (
    select * from {{ ref('stg_jira__issues') }}
),

filtered as (
    select * from source
    where issue_type in ('Task', 'Epic', 'Story')
),

cleaned as (
select
issue_id,
issue_key,
initcap(summary) as summary,
issue_type,
current_status,
project_key,
project_name,
assignee_name,
reporter_name,
created_at,
updated_at,
extracted_at
from filtered
)

select * from cleaned