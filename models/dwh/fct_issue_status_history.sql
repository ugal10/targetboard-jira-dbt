with changelogs as (
    select * from {{ ref('stg_jira__changelogs') }}
),

items as (
    select * from {{ ref('stg_jira__changelogs_items') }}
),

issues as (
    select * from {{ ref('dim_issues') }}
),


status_changes as (
select
        i.issue_id,
        i.issue_key,
        c.changed_at,
        ci.from_value   as from_status,
        ci.to_value     as to_status
    from changelogs c
    inner join items ci
        on c.changelog_id = ci.changelog_id
    inner join issues i
        on c.issue_id = i.issue_id
    where ci.field_name = 'status'
),


initial_status as (
    select
i.issue_id,
i.issue_key,
i.created_at as changed_at,
        null::text   as from_status,
        sc.to_status  as to_status
    from issues i
    inner join (
        select distinct on (issue_id)
            issue_id,
            from_status as to_status
        from status_changes
        order by issue_id, changed_at asc
    ) sc on sc.issue_id = i.issue_id
),

combined as (
select * from status_changes
union all
select * from initial_status
)

select * from combined
order by issue_key, changed_at