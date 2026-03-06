CREATE OR REPLACE FUNCTION dbt_dev_gal.issue_status_as_of(
    p_issue_key text,
    p_date date
)
RETURNS TABLE (
    issue_key text,
    summary text,
    status_as_of text
)
LANGUAGE sql
AS $$
    with issue as (
        select
         issue_id,
         issue_key,
         summary,
         created_at
        from dbt_dev_gal.dim_issues
        where issue_key = p_issue_key
    ),

   
    status_history as (
        select
        fsh.issue_key,
        fsh.changed_at,
        fsh.to_status
        from dbt_dev_gal.fct_issue_status_history fsh
        inner join issue i on fsh.issue_key = i.issue_key
        where fsh.changed_at::date <= p_date
    ),

   
    latest_status as (
        select distinct on (issue_key)
        issue_key,
        to_status
        from status_history
        order by issue_key, changed_at desc
    )

    select
    i.issue_key,
    i.summary,
    ls.to_status as status_as_of
    from issue i
    left join latest_status ls on ls.issue_key = i.issue_key;
$$;