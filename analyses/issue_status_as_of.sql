-- Example: Get the status of an issue as of a specific date
-- TB-22 was "To Do" before 2024-10-27, then moved to "Ready for Dev"

-- Returns "To Do"
select * from dbt_dev_gal.issue_status_as_of('TB-22', '2024-10-01');
